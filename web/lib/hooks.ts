"use client";

import { useCallback, useEffect, useState } from "react";
import { DEMO_MODE, supabase } from "./supabase";
import { rangeFor, type RangePreset } from "./format";
import { ApiError, type DateRange } from "./types";

export type SessionState = "loading" | "signedIn" | "signedOut";

export function useSession(): { state: SessionState; email: string | null } {
  const [state, setState] = useState<SessionState>(DEMO_MODE ? "signedIn" : "loading");
  const [email, setEmail] = useState<string | null>(DEMO_MODE ? "demo@example.sch.uk" : null);

  useEffect(() => {
    if (DEMO_MODE) return;
    const client = supabase();
    client.auth.getSession().then(({ data }) => {
      setState(data.session ? "signedIn" : "signedOut");
      setEmail(data.session?.user.email ?? null);
    });
    const { data } = client.auth.onAuthStateChange((_event, session) => {
      setState(session ? "signedIn" : "signedOut");
      setEmail(session?.user.email ?? null);
    });
    return () => data.subscription.unsubscribe();
  }, []);

  return { state, email };
}

export function useAsync<T>(load: () => Promise<T>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<ApiError | null>(null);
  const [version, setVersion] = useState(0);

  // eslint-disable-next-line react-hooks/exhaustive-deps
  const run = useCallback(load, deps);

  useEffect(() => {
    let cancelled = false;
    setError(null);
    run()
      .then((value) => {
        if (!cancelled) setData(value);
      })
      .catch((e: unknown) => {
        if (cancelled) return;
        setError(e instanceof Error ? e.message : "Something went wrong");
        setStatus(e instanceof ApiError ? e : null);
      });
    return () => {
      cancelled = true;
    };
  }, [run, version]);

  return { data, error, apiError: status, reload: () => setVersion((v) => v + 1), setData };
}

/** Date range shared by the analytics pages and kept in the URL so reports can be bookmarked. */
export function useRange(): [RangePreset, DateRange, (preset: RangePreset) => void] {
  const [preset, setPreset] = useState<RangePreset>("30d");
  const [range, setRange] = useState<DateRange>(() => rangeFor("30d"));

  useEffect(() => {
    const stored = new URLSearchParams(window.location.search).get("range") as RangePreset | null;
    if (stored && ["7d", "30d", "90d", "year"].includes(stored)) {
      setPreset(stored);
      setRange(rangeFor(stored));
    }
  }, []);

  const choose = (next: RangePreset) => {
    setPreset(next);
    setRange(rangeFor(next));
    const url = new URL(window.location.href);
    url.searchParams.set("range", next);
    window.history.replaceState(null, "", url);
  };
  return [preset, range, choose];
}
