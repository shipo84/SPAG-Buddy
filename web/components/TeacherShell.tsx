"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { createContext, type ReactNode, useContext, useEffect, useState } from "react";
import { api } from "@/lib/api";
import { useSession } from "@/lib/hooks";
import { DEMO_MODE, supabase } from "@/lib/supabase";
import type { School, Teacher } from "@/lib/types";
import { ErrorBox, Loading } from "./ui";

interface TeacherContextValue {
  teacher: Teacher;
  school: School | null;
}

const TeacherContext = createContext<TeacherContextValue | null>(null);

export function useTeacher(): TeacherContextValue {
  const value = useContext(TeacherContext);
  if (!value) throw new Error("useTeacher must be used inside TeacherShell");
  return value;
}

export function TopBar({ email }: { email?: string | null }) {
  const router = useRouter();
  async function signOut() {
    if (!DEMO_MODE) await supabase().auth.signOut();
    router.replace("/sign-in");
  }
  return (
    <>
      {DEMO_MODE ? (
        <div className="demo-banner">Demo mode: every pupil and result here is made up, and changes are lost when you reload.</div>
      ) : null}
      <header className="topbar">
        <div className="topbar-inner">
          <Link href="/classes" className="brand">
            <span className="brand-mark" aria-hidden>
              Sb
            </span>
            SPAG Buddy
          </Link>
          <nav aria-label="Main">
            <Link href="/classes">Classes</Link>
            <Link href="/privacy">Privacy and data</Link>
          </nav>
          {email ? (
            <div className="who">
              <span>{email}</span>
              {!DEMO_MODE ? (
                <button type="button" className="btn secondary small" onClick={signOut}>
                  Sign out
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      </header>
    </>
  );
}

/**
 * Wraps signed-in pages. Sends signed-out visitors to /sign-in and teachers without a profile to /onboarding.
 */
export function TeacherShell({ children, requireProfile = true }: { children: ReactNode; requireProfile?: boolean }) {
  const router = useRouter();
  const { state, email } = useSession();
  const [profile, setProfile] = useState<TeacherContextValue | null | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (state === "signedOut") router.replace("/sign-in");
    if (state !== "signedIn") return;
    api()
      .me()
      .then((me) => {
        setProfile(me);
        if (!me && requireProfile) router.replace("/onboarding");
      })
      .catch((e: Error) => setError(e.message));
  }, [state, requireProfile, router]);

  let body: ReactNode;
  if (error) body = <ErrorBox message={error} onRetry={() => window.location.reload()} />;
  else if (state !== "signedIn" || profile === undefined || (requireProfile && !profile)) body = <Loading />;
  else if (!profile) body = children;
  else body = <TeacherContext.Provider value={profile}>{children}</TeacherContext.Provider>;

  return (
    <>
      <TopBar email={email} />
      <main className="page">{body}</main>
    </>
  );
}
