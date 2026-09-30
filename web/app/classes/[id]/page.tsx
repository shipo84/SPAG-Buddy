"use client";

import Link from "next/link";
import { useState } from "react";
import { useClass } from "@/components/ClassContext";
import { HeatMap } from "@/components/HeatMap";
import { Avatar, Empty, ErrorBox, LevelBar, Legend, Loading, RangePicker, Stat } from "@/components/ui";
import { api } from "@/lib/api";
import { downloadBlob } from "@/lib/download";
import { percent, relativeDays } from "@/lib/format";
import { useAsync, useRange } from "@/lib/hooks";
import { focusObjectives, pupilsToCheckIn } from "@/lib/insights";

export default function ClassOverview() {
  const { klass, pupils } = useClass();
  const [preset, range, setPreset] = useRange();
  const [hideUntried, setHideUntried] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);
  const { data, error, reload } = useAsync(() => api().classAnalytics(klass.id, range), [klass.id, range.from, range.to]);
  const query = `?range=${preset}`;

  async function exportCsv() {
    setExporting(true);
    setExportError(null);
    try {
      const { blob, filename } = await api().exportCsv(klass.id, range);
      downloadBlob(blob, filename);
    } catch (e) {
      setExportError((e as Error).message);
    } finally {
      setExporting(false);
    }
  }

  if (!pupils.length) {
    return (
      <div className="card">
        <Empty>
          <h2>No pupils yet</h2>
          <p>Add your pupils&apos; first names to get their login cards.</p>
          <Link className="btn" href={`/classes/${klass.id}/pupils`}>
            Add pupils
          </Link>
        </Empty>
      </div>
    );
  }

  const focus = data ? focusObjectives(data) : [];
  const checkIn = data ? pupilsToCheckIn(data) : [];

  return (
    <>
      <div className="row" style={{ marginBottom: "1rem" }}>
        <RangePicker value={preset} onChange={setPreset} />
        <span className="spacer" />
        <button className="btn secondary" type="button" onClick={exportCsv} disabled={exporting}>
          {exporting ? "Preparing…" : "Download answers (CSV)"}
        </button>
      </div>
      {exportError ? <ErrorBox message={exportError} /> : null}
      {error ? <ErrorBox message={error} onRetry={reload} /> : null}
      {!data && !error ? <Loading /> : null}
      {data ? (
        <>
          <div className="grid cols-4" style={{ marginBottom: "1rem" }}>
            <Stat label="Pupils practising" value={`${data.totals.activePupils} of ${data.pupils.length}`} />
            <Stat label="Questions answered" value={data.totals.attempts.toLocaleString("en-GB")} />
            <Stat label="Answers right" value={percent(data.totals.accuracy)} />
            <Stat label="Pupils needing support" value={data.pupils.filter((p) => p.needsSupport > 0).length} note="On at least one skill" />
          </div>

          <div className="grid cols-2" style={{ marginBottom: "1rem" }}>
            <section className="card" aria-labelledby="focus-title">
              <h2 id="focus-title">Skills to focus on</h2>
              {focus.length ? (
                <table>
                  <thead>
                    <tr>
                      <th>Skill</th>
                      <th>Pupils</th>
                      <th className="num">Right</th>
                    </tr>
                  </thead>
                  <tbody>
                    {focus.map((o) => (
                      <tr key={o.code}>
                        <td>
                          <Link href={`/classes/${klass.id}/objectives/${encodeURIComponent(o.code)}${query}`}>{o.title}</Link>
                          <div className="small muted">{o.levels.needsSupport} need support</div>
                        </td>
                        <td>
                          <LevelBar levels={o.levels} />
                        </td>
                        <td className="num">{percent(o.accuracy)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p className="muted">Nothing stands out yet. Skills appear here when several pupils find them hard.</p>
              )}
            </section>
            <section className="card" aria-labelledby="checkin-title">
              <h2 id="checkin-title">Pupils to check in with</h2>
              {checkIn.length ? (
                <table>
                  <tbody>
                    {checkIn.map(({ pupil, reason }) => (
                      <tr key={pupil.id}>
                        <td>
                          <Link href={`/pupils/${pupil.id}${query}`} className="pupil-name">
                            <Avatar avatarKey={pupil.avatarKey} />
                            {pupil.displayName}
                          </Link>
                        </td>
                        <td className="small muted">{reason}</td>
                        <td className="small muted num">{relativeDays(pupil.lastActiveAt)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p className="muted">Everyone is practising and nobody is stuck. Brilliant.</p>
              )}
            </section>
          </div>

          <section className="card" aria-labelledby="heat-title">
            <div className="row" style={{ marginBottom: "0.75rem" }}>
              <h2 id="heat-title" style={{ margin: 0 }}>
                Class heat map
              </h2>
              <span className="spacer" />
              <label className="row small" style={{ fontWeight: 400, margin: 0, gap: "0.35rem" }}>
                <input type="checkbox" checked={hideUntried} onChange={(e) => setHideUntried(e.target.checked)} />
                Hide skills nobody has tried
              </label>
            </div>
            <Legend />
            <div style={{ marginTop: "0.75rem" }}>
              <HeatMap data={data} classId={klass.id} query={query} hideUntried={hideUntried} />
            </div>
          </section>
        </>
      ) : null}
    </>
  );
}
