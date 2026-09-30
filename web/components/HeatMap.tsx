"use client";

import Link from "next/link";
import { strandName } from "@/lib/content";
import { LEVELS, percent } from "@/lib/format";
import type { ClassAnalyticsResponse, Level } from "@/lib/types";
import { Avatar } from "./ui";

export function HeatMap({ data, classId, query, hideUntried }: { data: ClassAnalyticsResponse; classId: string; query: string; hideUntried: boolean }) {
  const objectives = hideUntried ? data.objectives.filter((o) => o.attempts > 0) : data.objectives;
  const cells = new Map(data.cells.map((c) => [`${c.pupilId}|${c.objectiveCode}`, c]));

  if (!objectives.length) return <p className="muted">No answers in this date range yet.</p>;

  const strandGroups: { key: string; yearGroup: number; strand: string; span: number }[] = [];
  for (const o of objectives) {
    const last = strandGroups.at(-1);
    const key = `${o.yearGroup}-${o.strand}`;
    if (last?.key === key) last.span++;
    else strandGroups.push({ key, yearGroup: o.yearGroup, strand: o.strand, span: 1 });
  }

  return (
    <div className="table-wrap">
      <table className="heatmap">
        <caption className="small muted" style={{ textAlign: "left", captionSide: "bottom", paddingTop: "0.5rem" }}>
          Each square is one pupil on one skill, based on their last 10 answers. Select a skill name to see which questions caught pupils out.
        </caption>
        <thead>
          <tr>
            <td />
            {strandGroups.map((g) => (
              <th key={g.key} colSpan={g.span} className="heat-strand" style={{ height: "auto", paddingBottom: 0 }}>
                Y{g.yearGroup} {strandName(g.strand)}
              </th>
            ))}
          </tr>
          <tr>
            <th scope="col" style={{ verticalAlign: "bottom", textAlign: "left" }}>
              Pupil
            </th>
            {objectives.map((o) => (
              <th key={o.code} scope="col" title={o.title}>
                <Link className="rotate" href={`/classes/${classId}/objectives/${encodeURIComponent(o.code)}${query}`}>
                  {o.title}
                </Link>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.pupils.map((p) => (
            <tr key={p.id}>
              <th scope="row">
                <Link href={`/pupils/${p.id}${query}`} className="pupil-name" style={{ color: "inherit" }}>
                  <Avatar avatarKey={p.avatarKey} />
                  {p.displayName}
                </Link>
              </th>
              {objectives.map((o) => {
                const cell = cells.get(`${p.id}|${o.code}`);
                const level: Level = cell?.level ?? "notStarted";
                const info = LEVELS[level];
                const label = cell
                  ? `${p.displayName}, ${o.title}: ${info.label}. ${percent(cell.recentAccuracy)} of recent answers right, ${cell.attempts} answers.`
                  : `${p.displayName}, ${o.title}: not started.`;
                return (
                  <td key={o.code}>
                    <div className={`heat-cell ${info.className}`} title={label} aria-label={label} role="img">
                      {cell ? Math.round(cell.recentAccuracy * 100) : ""}
                    </div>
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
