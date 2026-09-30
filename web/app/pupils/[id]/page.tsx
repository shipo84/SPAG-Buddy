"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { DailyChart } from "@/components/DailyChart";
import { TeacherShell } from "@/components/TeacherShell";
import { ErrorBox, LevelPill, Loading, PupilName, RangePicker, Stat } from "@/components/ui";
import { api } from "@/lib/api";
import { SESSION_KINDS, spellingList, strandName } from "@/lib/content";
import { formatDateTime, percent, relativeDays } from "@/lib/format";
import { useAsync, useRange } from "@/lib/hooks";

function PupilDetail() {
  const { id } = useParams<{ id: string }>();
  const [preset, range, setPreset] = useRange();
  const { data, error, reload } = useAsync(() => api().pupilProgress(id, range), [id, range.from, range.to]);

  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!data) return <Loading />;

  const practised = data.objectives.filter((o) => o.attempts > 0);
  const byStrand = new Map<string, typeof practised>();
  for (const o of data.objectives) byStrand.set(o.strand, [...(byStrand.get(o.strand) ?? []), o]);

  return (
    <>
      <div className="crumbs">
        <Link href="/classes">Classes</Link> / <Link href={`/classes/${data.class.id}?range=${preset}`}>{data.class.name}</Link> / Pupil
      </div>
      <div className="page-head">
        <h1>
          <PupilName name={data.pupil.displayName} avatarKey={data.pupil.avatarKey} />
        </h1>
        <RangePicker value={preset} onChange={setPreset} />
      </div>

      <div className="grid cols-4" style={{ marginBottom: "1rem" }}>
        <Stat label="Questions answered" value={data.summary?.attempts ?? 0} />
        <Stat label="Answers right" value={percent(data.summary?.accuracy)} />
        <Stat label="Skills secure" value={`${data.objectives.filter((o) => o.level === "secure").length} of ${data.objectives.length}`} />
        <Stat label="Last practised" value={relativeDays(data.summary?.lastActiveAt)} />
      </div>

      <section className="card">
        <h2>Practice each day</h2>
        <DailyChart daily={data.daily} range={data.range} />
      </section>

      <div className="grid cols-2" style={{ alignItems: "start", marginTop: "1rem" }}>
        <section className="card">
          <h2>Skills</h2>
          {practised.length === 0 ? <p className="muted">No answers in this date range.</p> : null}
          {[...byStrand.entries()].map(([strand, objectives]) => (
            <div key={strand} style={{ marginBottom: "1rem" }}>
              <h3 className="muted small" style={{ textTransform: "uppercase" }}>
                {strandName(strand)}
              </h3>
              <table>
                <tbody>
                  {objectives.map((o) => (
                    <tr key={o.code}>
                      <td>
                        <Link href={`/classes/${data.class.id}/objectives/${encodeURIComponent(o.code)}?range=${preset}`}>{o.title}</Link>
                        <div className="small muted">Year {o.yearGroup}</div>
                      </td>
                      <td>
                        <LevelPill level={o.level} />
                      </td>
                      <td className="num small muted">{o.attempts ? `${percent(o.recentAccuracy)} recently` : ""}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
        </section>

        <div>
          <section className="card">
            <h2>Spelling lists</h2>
            {data.spelling.length ? (
              <table>
                <thead>
                  <tr>
                    <th>List</th>
                    <th className="num">Tried</th>
                    <th className="num">Got right last time</th>
                  </tr>
                </thead>
                <tbody>
                  {data.spelling.map((s) => {
                    const list = spellingList(s.spellingListId);
                    return (
                      <tr key={s.spellingListId}>
                        <td>{list?.title ?? s.spellingListId}</td>
                        <td className="num">
                          {s.wordsAttempted}
                          {list ? ` of ${list.wordCount}` : ""}
                        </td>
                        <td className="num">{s.wordsMastered}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            ) : (
              <p className="muted">No spelling practice yet.</p>
            )}
          </section>
          <section className="card">
            <h2>Recent sessions</h2>
            {data.sessions.length ? (
              <table>
                <tbody>
                  {data.sessions.map((s) => (
                    <tr key={s.sessionId}>
                      <td>
                        {SESSION_KINDS[s.kind] ?? s.kind}
                        <div className="small muted">{s.strands.map(strandName).join(", ")}</div>
                      </td>
                      <td className="small muted">{formatDateTime(s.startedAt)}</td>
                      <td className="num">
                        {s.correct}/{s.attempts}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="muted">No sessions yet.</p>
            )}
          </section>
        </div>
      </div>
    </>
  );
}

export default function PupilPage() {
  return (
    <TeacherShell>
      <PupilDetail />
    </TeacherShell>
  );
}
