"use client";

import { type FormEvent, useState } from "react";
import { useClass } from "@/components/ClassContext";
import { Empty, ErrorBox, Loading } from "@/components/ui";
import { api } from "@/lib/api";
import { objectivesForYear, objectiveTitle, QUESTIONS, spellingList, spellingListsForYear, strandName } from "@/lib/content";
import { formatDate, percent } from "@/lib/format";
import { useAsync } from "@/lib/hooks";

const PRACTISABLE = new Set(QUESTIONS.map((q) => q.objectiveCode));

function NewAssignment({ onCreated, onCancel }: { onCreated: () => void; onCancel: () => void }) {
  const { klass, pupils } = useClass();
  const objectives = objectivesForYear(klass.yearGroup).filter((o) => PRACTISABLE.has(o.code));
  const lists = spellingListsForYear(klass.yearGroup);
  const [title, setTitle] = useState("");
  const [codes, setCodes] = useState<string[]>([]);
  const [listId, setListId] = useState("");
  const [everyone, setEveryone] = useState(true);
  const [pupilIds, setPupilIds] = useState<string[]>([]);
  const [dueDate, setDueDate] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggle = (list: string[], value: string) => (list.includes(value) ? list.filter((v) => v !== value) : [...list, value]);
  const valid = title.trim() && (codes.length || listId) && (everyone || pupilIds.length);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api().createAssignment({
        classId: klass.id,
        title: title.trim(),
        objectiveCodes: codes,
        spellingListId: listId || null,
        pupilIds: everyone ? null : pupilIds,
        dueDate: dueDate || null,
      });
      onCreated();
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  }

  return (
    <form className="card" onSubmit={submit} style={{ marginBottom: "1rem" }}>
      <h2>Set new work</h2>
      <p className="muted small">It appears on pupils&apos; iPads next time they connect to the internet.</p>
      {error ? <ErrorBox message={error} /> : null}
      <div className="grid cols-2">
        <div className="field">
          <label htmlFor="title">Title pupils will see</label>
          <input id="title" type="text" required maxLength={80} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Apostrophes this week" />
        </div>
        <div className="field">
          <label htmlFor="due">Due date (optional)</label>
          <input id="due" type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
        </div>
      </div>
      <fieldset className="field" style={{ border: "none", padding: 0, margin: "0 0 1rem" }}>
        <legend style={{ fontWeight: 600, fontSize: "0.9rem", marginBottom: "0.3rem" }}>Skills</legend>
        <div className="checkbox-list">
          {objectives.map((o) => (
            <label key={o.code}>
              <input type="checkbox" checked={codes.includes(o.code)} onChange={() => setCodes((c) => toggle(c, o.code))} />
              <span>
                {o.title}
                <span className="small muted">
                  {" "}
                  · Y{o.yearGroup} {strandName(o.strand)}
                </span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <div className="field">
        <label htmlFor="list">Spelling list (optional)</label>
        <select id="list" value={listId} onChange={(e) => setListId(e.target.value)}>
          <option value="">No spelling list</option>
          {lists.map((l) => (
            <option key={l.id} value={l.id}>
              {l.title} ({l.wordCount} words)
            </option>
          ))}
        </select>
      </div>
      <fieldset className="field" style={{ border: "none", padding: 0, margin: "0 0 1rem" }}>
        <legend style={{ fontWeight: 600, fontSize: "0.9rem", marginBottom: "0.3rem" }}>Who is it for?</legend>
        <div className="row">
          <label className="row" style={{ fontWeight: 400, margin: 0, gap: "0.35rem" }}>
            <input type="radio" name="who" checked={everyone} onChange={() => setEveryone(true)} /> The whole class
          </label>
          <label className="row" style={{ fontWeight: 400, margin: 0, gap: "0.35rem" }}>
            <input type="radio" name="who" checked={!everyone} onChange={() => setEveryone(false)} /> Some pupils
          </label>
        </div>
        {!everyone ? (
          <div className="checkbox-list" style={{ marginTop: "0.5rem" }}>
            {pupils.map((p) => (
              <label key={p.id}>
                <input type="checkbox" checked={pupilIds.includes(p.id)} onChange={() => setPupilIds((ids) => toggle(ids, p.id))} />
                {p.displayName}
              </label>
            ))}
          </div>
        ) : null}
      </fieldset>
      <div className="row">
        <button className="btn" type="submit" disabled={busy || !valid}>
          {busy ? "Saving…" : "Set work"}
        </button>
        <button className="btn secondary" type="button" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </form>
  );
}

export default function AssignmentsPage() {
  const { klass } = useClass();
  const { data, error, reload } = useAsync(() => api().listAssignments(klass.id), [klass.id]);
  const [creating, setCreating] = useState(false);

  async function archive(id: string, title: string) {
    if (!window.confirm(`Remove "${title}" from pupils' iPads? Answers already given are kept.`)) return;
    await api().archiveAssignment(id);
    reload();
  }

  return (
    <>
      <div className="row" style={{ marginBottom: "1rem" }}>
        <span className="spacer" />
        {!creating ? (
          <button className="btn" type="button" onClick={() => setCreating(true)}>
            Set new work
          </button>
        ) : null}
      </div>
      {creating ? (
        <NewAssignment
          onCancel={() => setCreating(false)}
          onCreated={() => {
            setCreating(false);
            reload();
          }}
        />
      ) : null}
      {error ? <ErrorBox message={error} onRetry={reload} /> : null}
      {!data && !error ? <Loading /> : null}
      {data && !data.length ? (
        <div className="card">
          <Empty>
            <h2>No work set</h2>
            <p>Set a few skills or a spelling list and pupils will see it at the top of their home screen.</p>
          </Empty>
        </div>
      ) : null}
      {data?.length ? (
        <div className="card table-wrap">
          <table>
            <thead>
              <tr>
                <th>Work</th>
                <th>Due</th>
                <th className="num">Started</th>
                <th className="num">Answers</th>
                <th className="num">Right</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {data.map((a) => (
                <tr key={a.id}>
                  <td>
                    <strong>{a.title}</strong>
                    <div className="small muted">
                      {[...a.objectiveCodes.map(objectiveTitle), ...(a.spellingListId ? [spellingList(a.spellingListId)?.title ?? a.spellingListId] : [])].join(" · ")}
                    </div>
                    <div className="small muted">{a.pupilIds ? `${a.pupilIds.length} chosen pupils` : "Whole class"}</div>
                  </td>
                  <td className="small">{a.dueDate ? formatDate(a.dueDate) : "–"}</td>
                  <td className="num">
                    {a.pupilsStarted} of {a.assignedPupils}
                  </td>
                  <td className="num">{a.attempts}</td>
                  <td className="num">{percent(a.accuracy)}</td>
                  <td className="num">
                    <button className="btn secondary small" type="button" onClick={() => archive(a.id, a.title)}>
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </>
  );
}
