"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Loading } from "@/components/ui";
import { DEMO_MODE, supabase } from "@/lib/supabase";

/** The magic link lands here. Supabase swaps the one-time code in the URL for a session. */
export default function AuthCallback() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (DEMO_MODE) {
      router.replace("/classes");
      return;
    }
    const params = new URLSearchParams(window.location.search);
    const code = params.get("code");
    const failure = params.get("error_description");
    if (failure) {
      setError(failure);
      return;
    }
    const client = supabase();
    (code ? client.auth.exchangeCodeForSession(code) : client.auth.getSession()).then(({ data, error }) => {
      if (error) setError(error.message);
      else if (data.session) router.replace("/classes");
      else setError("That sign-in link has expired or has already been used.");
    });
  }, [router]);

  return (
    <main className="page">
      <div className="narrow card">
        {error ? (
          <>
            <h1>Sign-in link did not work</h1>
            <p>{error}</p>
            <Link className="btn" href="/sign-in">
              Send a new link
            </Link>
          </>
        ) : (
          <Loading label="Signing you in…" />
        )}
      </div>
    </main>
  );
}
