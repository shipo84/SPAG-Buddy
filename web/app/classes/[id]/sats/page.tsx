"use client";

import Link from "next/link";
import { useClass } from "@/components/ClassContext";
import { ErrorBox, Loading, PupilName, RangePicker, Stat } from "@/components/ui";
import { api } from "@/lib/api";
import { STRANDS } from "@/lib/content";
import { percent, SATS_BANDS } from "@/lib/format";
import { useAsync, useRange } from "@/lib/hooks";
import type { SatsBand } from "@/lib/types";

export default function SatsPage() {
  const { klass } = useClass();
  const [preset, range, setPreset] = useRange();
  const { data, error, reload } = useAsync(() => api().sats(klass.id, range), [klass.id, range.from, range.to]);
  const strands = Object.keys(STRANDS);

  const counts = (data?.pupils ?? []).reduce<Record<SatsBand, number>>(
    (acc, p) => ({ ...acc, [p.band]: acc[p.band] + 1 }),
    { onTrack: 0, nearly: 0, needsSupport: 0, notEnoughData: 0 },
  );

  return (
    <>
      <div className="alert">
        This is an indicative guide from SATs-style practice questions in SPAG Buddy. It is not a scaled score and does not predict a
        pupil&apos;s KS2 grammar, punctuation and spelling result. Use it alongside your own assessment.
      </div>
      <div className="row" style={{ marginBottom: "1rem" }}>
        <RangePicker value={preset} onChange={setPreset} />
      </div>
      {error ? <ErrorBox message={error} onRetry={reload} /> : null}
      {!data && !error ? <Loading /> : null}
      {data ? (
        <>
          <div className="grid cols-4" style={{ marginBottom: "1rem" }}>
            {(Object.keys(SATS_BANDS) as SatsBand[]).map((band) => (
              <Stat key={band} label={SATS_BANDS[band].label} value={counts[band]} />
            ))}
          </div>
          <div className="card table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Pupil</th>
                  <th>Guide</th>
                  <th className="num">Answers</th>
                  <th className="num">Right</th>
                  {strands.map((s) => (
                    <th key={s} className="num">
                      {STRANDS[s]}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.pupils.map((p) => (
                  <tr key={p.pupilId}>
                    <td>
                      <Link href={`/pupils/${p.pupilId}?range=${preset}`} style={{ color: "inherit" }}>
                        <PupilName name={p.displayName} avatarKey={p.avatarKey} />
                      </Link>
                    </td>
                    <td>
                      <span className={`pill ${SATS_BANDS[p.band].className}`}>{SATS_BANDS[p.band].label}</span>
                    </td>
                    <td className="num">{p.attempts}</td>
                    <td className="num">{percent(p.accuracy)}</td>
                    {strands.map((s) => (
                      <td key={s} className="num small">
                        {p.strands[s] ? percent(p.strands[s].accuracy) : "–"}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="small muted" style={{ marginTop: "0.75rem" }}>
            Pupils need at least 10 SATs-style answers in the date range before a guide is shown. On track means 70% or more right, nearly there
            means 50% to 69%.
          </p>
        </>
      ) : null}
    </>
  );
}
