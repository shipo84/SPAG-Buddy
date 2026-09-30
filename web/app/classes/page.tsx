"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { type FormEvent, useState } from "react";
import { TeacherShell, useTeacher } from "@/components/TeacherShell";
import { Empty, ErrorBox, Loading } from "@/components/ui";
import { api } from "@/lib/api";
import { useAsync } from "@/lib/hooks";

function CreateClass({ onCancel }: { onCancel: () => void }) {
  const router = useRouter();
  const [name, setName] = useState("");
  const [yearGroup, setYearGroup] = useState(4);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      const created = await api().createClass({ name: name.trim(), yearGroup });
      router.push(`/classes/${created.id}/pupils`);
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  }

  return (
    <form className="card" onSubmit={submit} style={{ marginBottom: "1rem" }}>
      <h2>New class</h2>
      {error ? <ErrorBox message={error} /> : null}
      <div className="grid cols-2">
        <div className="field">
          <label htmlFor="class-name">Class name</label>
          <input id="class-name" type="text" required maxLength={60} value={name} onChange={(e) => setName(e.target.value)} placeholder="Kestrels" />
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
        </div>
      </div>
      <div className="row">
        <button className="btn" type="submit" disabled={busy}>
          {busy ? "Creating…" : "Create class"}
        </button>
        <button className="btn secondary" type="button" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </form>
  );
}

function ClassList() {
  const { teacher, school } = useTeacher();
  const { data, error, reload } = useAsync(() => api().listClasses(), []);
  const [creating, setCreating] = useState(false);
  const [showArchived, setShowArchived] = useState(false);

  const classes = data?.filter((c) => showArchived || !c.archived) ?? [];
  const archivedCount = data?.filter((c) => c.archived).length ?? 0;

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Your classes</h1>
          <p>
            {teacher.displayName}
            {school ? `, ${school.name}` : ""}
          </p>
        </div>
        {!creating ? (
          <button className="btn" type="button" onClick={() => setCreating(true)}>
            New class
          </button>
        ) : null}
      </div>
      {creating ? <CreateClass onCancel={() => setCreating(false)} /> : null}
      {error ? <ErrorBox message={error} onRetry={reload} /> : null}
      {!data && !error ? <Loading /> : null}
      {data && classes.length === 0 ? (
        <div className="card">
          <Empty>
            <h2>No classes yet</h2>
            <p>Create a class, add your pupils&apos; first names and print their login cards.</p>
          </Empty>
        </div>
      ) : null}
      <div className="grid cols-3">
        {classes.map((c) => (
          <Link key={c.id} href={`/classes/${c.id}`} className="card class-card">
            <div className="row">
              <h2 style={{ margin: 0 }}>{c.name}</h2>
              <span className="spacer" />
              {c.archived ? <span className="pill level-none">Archived</span> : null}
            </div>
            <p className="muted" style={{ margin: "0.25rem 0 0.75rem" }}>
              Year {c.yearGroup} · {c.pupilCount ?? 0} pupils
            </p>
            <span className="small muted">
              Class code <span className="code">{c.classCode}</span>
            </span>
          </Link>
        ))}
      </div>
      {archivedCount ? (
        <p style={{ marginTop: "1rem" }}>
          <button type="button" className="btn link" onClick={() => setShowArchived((v) => !v)}>
            {showArchived ? "Hide archived classes" : `Show ${archivedCount} archived ${archivedCount === 1 ? "class" : "classes"}`}
          </button>
        </p>
      ) : null}
    </>
  );
}

export default function ClassesPage() {
  return (
    <TeacherShell>
      <ClassList />
    </TeacherShell>
  );
}
