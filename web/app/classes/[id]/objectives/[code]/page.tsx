"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useClass } from "@/components/ClassContext";
import { ErrorBox, LevelPill, Loading, PupilName, RangePicker } from "@/components/ui";
import { api } from "@/lib/api";
import { strandName } from "@/lib/content";
import { LEVEL_ORDER, percent } from "@/lib/format";
import { useAsync, useRange } from "@/lib/hooks";

export default function ObjectivePage() {
  const { klass } = useClass();
  const params = useParams<{ code: string }>();
  const code = decodeURIComponent(params.code);
  const [preset, range, setPreset] = useRange();
  const { data, error, reload } = useAsync(() => api().objectiveDetail(klass.id, code, range), [klass.id, code, range.from, range.to]);

  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!data) return <Loading />;

  const pupils = [...data.pupils].sort((a, b) => LEVEL_ORDER.indexOf(a.level) - LEVEL_ORDER.indexOf(b.level) || (a.accuracy ?? 2) - (b.accuracy ?? 2));

  return (
    <>
      <div className="crumbs">
        <Link href={`/classes/${klass.id}?range=${preset}`}>Overview</Link> / Skill
      </div>
      <div className="page-head">
        <div>
          <h2 style={{ fontSize: "1.35rem" }}>{data.objective.title}</h2>
          <p>
            Year {data.objective.year_group} {strandName(data.objective.strand)} · pupils see &ldquo;{data.objective.child_title}&rdquo;
          </p>
        </div>
        <RangePicker value={preset} onChange={setPreset} />
      </div>
      <div className="alert">
        <strong>The rule pupils are shown:</strong> {data.objective.rule}
      </div>

      <div className="grid cols-2" style={{ alignItems: "start" }}>
        <section className="card" aria-labelledby="mis-title">
          <h3 id="mis-title">Common wrong answers</h3>
          {data.misconceptions.length ? (
            <table>
              <thead>
                <tr>
                  <th>Question and wrong answer</th>
                  <th className="num">Pupils</th>
                </tr>
              </thead>
              <tbody>
                {data.misconceptions.map((m) => (
                  <tr key={`${m.questionId}-${m.answerGiven}`}>
                    <td>
                      <div className="small muted">{m.prompt}</div>
                      <div>&ldquo;{m.answerGiven}&rdquo;</div>
                    </td>
                    <td className="num">{m.pupils}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <p className="muted">No wrong answers to show in this date range.</p>
          )}
        </section>

        <section className="card" aria-labelledby="pupils-title">
          <h3 id="pupils-title">Pupils</h3>
          <table>
            <tbody>
              {pupils.map((p) => (
                <tr key={p.id}>
                  <td>
                    <Link href={`/pupils/${p.id}?range=${preset}`} style={{ color: "inherit" }}>
                      <PupilName name={p.displayName} avatarKey={p.avatarKey} />
                    </Link>
                  </td>
                  <td>
                    <LevelPill level={p.level} />
                  </td>
                  <td className="num small muted">{p.attempts ? `${percent(p.accuracy)} of ${p.attempts}` : ""}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </div>

      <section className="card" aria-labelledby="q-title" style={{ marginTop: "1rem" }}>
        <h3 id="q-title">Questions, hardest first</h3>
        {data.questions.length ? (
          <table>
            <thead>
              <tr>
                <th>Question</th>
                <th className="num">Pupils</th>
                <th className="num">Answers</th>
                <th className="num">Right</th>
              </tr>
            </thead>
            <tbody>
              {data.questions.map((q) => (
                <tr key={q.questionId}>
                  <td>{q.prompt}</td>
                  <td className="num">{q.pupils}</td>
                  <td className="num">{q.attempts}</td>
                  <td className="num">{percent(q.accuracy)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="muted">Nobody has answered questions on this skill in this date range.</p>
        )}
      </section>
    </>
  );
}
