"use client";

import { useRouter } from "next/navigation";
import { type FormEvent, useState } from "react";
import { TeacherShell } from "@/components/TeacherShell";
import { api } from "@/lib/api";

function OnboardingForm() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [schoolName, setSchoolName] = useState("");
  const [urn, setUrn] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api().saveProfile({ displayName: displayName.trim(), schoolName: schoolName.trim(), urn: urn.trim() || null });
      router.replace("/classes");
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  }

  return (
    <div className="narrow card">
      <h1>Welcome to SPAG Buddy</h1>
      <p className="muted">Tell us a little about you and your school. Pupils see your name as it appears here.</p>
      <form onSubmit={submit}>
        {error ? (
          <div className="alert error" role="alert">
            {error}
          </div>
        ) : null}
        <div className="field">
          <label htmlFor="name">Your name</label>
          <input id="name" type="text" required maxLength={80} value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder="Ms Patel" />
        </div>
        <div className="field">
          <label htmlFor="school">School name</label>
          <input id="school" type="text" required maxLength={120} value={schoolName} onChange={(e) => setSchoolName(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="urn">School URN (optional)</label>
          <input id="urn" type="text" inputMode="numeric" pattern="\d{6,7}" value={urn} onChange={(e) => setUrn(e.target.value)} />
          <p className="hint">The 6 or 7-digit number from Get Information about Schools. It helps us match your school&apos;s data agreement.</p>
        </div>
        <button className="btn" type="submit" disabled={busy}>
          {busy ? "Saving…" : "Continue"}
        </button>
      </form>
    </div>
  );
}

export default function Onboarding() {
  return (
    <TeacherShell requireProfile={false}>
      <OnboardingForm />
    </TeacherShell>
  );
}
