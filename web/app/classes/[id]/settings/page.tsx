"use client";

import { useRouter } from "next/navigation";
import { type FormEvent, useState } from "react";
import { useClass } from "@/components/ClassContext";
import { ErrorBox } from "@/components/ui";
import { api } from "@/lib/api";

export default function ClassSettings() {
  const router = useRouter();
  const { klass, reload } = useClass();
  const [name, setName] = useState(klass.name);
  const [yearGroup, setYearGroup] = useState(klass.yearGroup);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmText, setConfirmText] = useState("");

  async function run(action: () => Promise<unknown>) {
    setError(null);
    setSaved(false);
    try {
      await action();
      return true;
    } catch (e) {
      setError((e as Error).message);
      return false;
    }
  }

  async function save(event: FormEvent) {
    event.preventDefault();
    if (await run(() => api().updateClass(klass.id, { name: name.trim(), yearGroup }))) {
      setSaved(true);
      reload();
    }
  }

  async function toggleArchive() {
    if (!klass.archived && !window.confirm(`Archive ${klass.name}? Pupils can no longer join or send answers. Everything is deleted 12 months after archiving.`)) return;
    if (await run(() => api().updateClass(klass.id, { archived: !klass.archived }))) reload();
  }

  async function remove() {
    if (await run(() => api().deleteClass(klass.id))) router.replace("/classes");
  }

  return (
    <div className="grid cols-2" style={{ alignItems: "start" }}>
      <form className="card" onSubmit={save}>
        <h2>Class details</h2>
        {error ? <ErrorBox message={error} /> : null}
        {saved ? (
          <div className="alert" role="status">
            Saved.
          </div>
        ) : null}
        <div className="field">
          <label htmlFor="name">Class name</label>
          <input id="name" type="text" required maxLength={60} value={name} onChange={(e) => setName(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="year">Year group</label>
          <select id="year" value={yearGroup} onChange={(e) => setYearGroup(Number(e.target.value))}>
            {[1, 2, 3, 4, 5, 6].map((y) => (
              <option key={y} value={y}>
                Year {y}
              </option>
            ))}
          </select>
          <p className="hint">Move the class up a year in September to keep its history.</p>
        </div>
        <button className="btn" type="submit">
          Save
        </button>
      </form>

      <div>
        <section className="card">
          <h2>{klass.archived ? "Archived class" : "End of the year"}</h2>
          <p className="muted">
            {klass.archived
              ? "This class is archived. Its results are still here for reports, and it is deleted automatically 12 months after it was archived."
              : "Archive the class when pupils move on. They can no longer sign in, and everything is deleted automatically after 12 months."}
          </p>
          <button className="btn secondary" type="button" onClick={toggleArchive}>
            {klass.archived ? "Restore class" : "Archive class"}
          </button>
        </section>
        <section className="card">
          <h2>Delete class now</h2>
          <p className="muted">
            Permanently deletes the class, every pupil in it and all their answers, for example to meet a request to erase data. This cannot be
            undone.
          </p>
          <div className="field">
            <label htmlFor="confirm">
              Type <span className="code">{klass.classCode}</span> to confirm
            </label>
            <input id="confirm" type="text" autoComplete="off" value={confirmText} onChange={(e) => setConfirmText(e.target.value.toUpperCase())} />
          </div>
          <button className="btn danger" type="button" disabled={confirmText !== klass.classCode} onClick={remove}>
            Delete class and all data
          </button>
        </section>
      </div>
    </div>
  );
}
