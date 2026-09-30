"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";
import { TopBar } from "@/components/TeacherShell";
import { DEMO_MODE, supabase } from "@/lib/supabase";

export default function SignIn() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    const { error } = await supabase().auth.signInWithOtp({
      email: email.trim(),
      options: { emailRedirectTo: `${window.location.origin}/auth/callback`, shouldCreateUser: true },
    });
    setBusy(false);
    if (error) setError(error.message);
    else setSent(true);
  }

  return (
    <>
      <TopBar />
      <main className="page">
        <div className="narrow card">
          <h1>Sign in</h1>
          <p className="muted">SPAG Buddy for teachers. See how your class is getting on with spelling, punctuation and grammar.</p>
          {DEMO_MODE ? (
            <p>
              This is the demo. <Link href="/classes">Go to the demo classes</Link>.
            </p>
          ) : sent ? (
            <div className="alert" role="status">
              Check your email. We have sent a sign-in link to <strong>{email}</strong>. It works once and runs out after an hour.
            </div>
          ) : (
            <form onSubmit={submit}>
              {error ? (
                <div className="alert error" role="alert">
                  {error}
                </div>
              ) : null}
              <div className="field">
                <label htmlFor="email">School email address</label>
                <input
                  id="email"
                  type="email"
                  required
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@school.sch.uk"
                />
                <p className="hint">Use your school account, not a personal one. We will email you a link, so there is no password to remember.</p>
              </div>
              <button className="btn" type="submit" disabled={busy || !email}>
                {busy ? "Sending…" : "Email me a sign-in link"}
              </button>
            </form>
          )}
        </div>
      </main>
    </>
  );
}
