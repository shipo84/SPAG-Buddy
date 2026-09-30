"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { type FormEvent, useState } from "react";
import { useClass } from "@/components/ClassContext";
import { ErrorBox, PupilName } from "@/components/ui";
import { api } from "@/lib/api";
import { AVATARS } from "@/lib/content";
import { saveLoginCards } from "@/lib/login-cards";
import { parseNames, pupilNameProblem } from "@/lib/names";
import type { LoginCards, Pupil } from "@/lib/types";

function PupilRow({ pupil, onChanged, onCards }: { pupil: Pupil; onChanged: () => void; onCards: (ids: string[]) => void }) {
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(pupil.displayName);
  const [error, setError] = useState<string | null>(null);

  async function rename(event: FormEvent) {
    event.preventDefault();
    try {
      await api().renamePupil(pupil.id, name);
      setEditing(false);
      onChanged();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function remove() {
    const ok = window.confirm(
      `Delete ${pupil.displayName}? This permanently removes their results from SPAG Buddy. Their iPad will need to join again.`,
    );
    if (!ok) return;
    try {
      await api().deletePupil(pupil.id);
      onChanged();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <tr>
      <td>
        {editing ? (
          <form className="row" onSubmit={rename}>
            <input type="text" aria-label="First name" value={name} maxLength={30} onChange={(e) => setName(e.target.value)} style={{ maxWidth: 220 }} />
            <button className="btn small" type="submit">
              Save
            </button>
            <button className="btn secondary small" type="button" onClick={() => setEditing(false)}>
              Cancel
            </button>
          </form>
        ) : (
          <Link href={`/pupils/${pupil.id}`} style={{ color: "inherit" }}>
            <PupilName name={pupil.displayName} avatarKey={pupil.avatarKey} />
          </Link>
        )}
        {error ? <div className="small" style={{ color: "var(--danger)" }}>{error}</div> : null}
      </td>
      <td className="small muted">{AVATARS.find((a) => a.key === pupil.avatarKey)?.name}</td>
      <td className="small">{pupil.locked ? <span className="pill level-support">Locked after wrong PINs</span> : null}</td>
      <td className="num">
        <div className="row" style={{ justifyContent: "flex-end" }}>
          <button className="btn secondary small" type="button" onClick={() => onCards([pupil.id])}>
            New PIN
          </button>
          <button className="btn secondary small" type="button" onClick={() => setEditing(true)}>
            Rename
          </button>
          <button className="btn danger secondary small" type="button" onClick={remove}>
            Delete
          </button>
        </div>
      </td>
    </tr>
  );
}

export default function PupilsPage() {
  const router = useRouter();
  const { klass, pupils, reload } = useClass();
  const [names, setNames] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const parsed = parseNames(names);
  const problems = parsed.map(pupilNameProblem).filter((p): p is string => p !== null);
  const spaces = AVATARS.length - pupils.length;

  function showCards(cards: LoginCards) {
    saveLoginCards(klass.id, cards);
    router.push(`/classes/${klass.id}/login-cards`);
  }

  async function add(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      showCards(await api().addPupils(klass.id, parsed));
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  }

  async function newCards(pupilIds?: string[]) {
    const who = pupilIds?.length === 1 ? pupils.find((p) => p.id === pupilIds[0])?.displayName : "every pupil in the class";
    const ok = window.confirm(
      `Make a new PIN for ${who}? The old PIN stops working. iPads that have already joined stay signed in.`,
    );
    if (!ok) return;
    setError(null);
    try {
      showCards(await api().loginCards(klass.id, pupilIds));
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <div className="grid cols-2" style={{ alignItems: "start" }}>
      <section className="card" aria-labelledby="pupils-title">
        <div className="row" style={{ marginBottom: "0.5rem" }}>
          <h2 id="pupils-title" style={{ margin: 0 }}>
            Pupils
          </h2>
          <span className="spacer" />
          {pupils.length ? (
            <button className="btn secondary small" type="button" onClick={() => newCards()}>
              Print new cards for everyone
            </button>
          ) : null}
        </div>
        {pupils.length ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Picture</th>
                  <th />
                  <th />
                </tr>
              </thead>
              <tbody>
                {pupils.map((p) => (
                  <PupilRow key={p.id} pupil={p} onChanged={reload} onCards={newCards} />
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="muted">No pupils yet. Add their first names to make login cards.</p>
        )}
      </section>

      <section className="card" aria-labelledby="add-title">
        <h2 id="add-title">Add pupils</h2>
        {error ? <ErrorBox message={error} /> : null}
        <form onSubmit={add}>
          <div className="field">
            <label htmlFor="names">First names, one per line</label>
            <textarea id="names" value={names} onChange={(e) => setNames(e.target.value)} placeholder={"Amara\nBen\nChloe K"} />
            <p className="hint">
              Use first names or nicknames only, with an initial if two children share a name. Do not type surnames, dates of birth or UPNs.
              Each pupil gets a picture and a 4-digit PIN. {spaces} spaces left in this class.
            </p>
          </div>
          {problems.length ? (
            <div className="alert error" role="alert">
              {problems.map((p) => (
                <div key={p}>{p}</div>
              ))}
            </div>
          ) : null}
          <button className="btn" type="submit" disabled={busy || parsed.length === 0 || parsed.length > spaces || problems.length > 0}>
            {busy ? "Adding…" : parsed.length ? `Add ${parsed.length} ${parsed.length === 1 ? "pupil" : "pupils"} and print cards` : "Add pupils"}
          </button>
        </form>
      </section>
    </div>
  );
}
