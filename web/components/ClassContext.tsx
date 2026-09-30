"use client";

import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { createContext, type ReactNode, useContext } from "react";
import { api } from "@/lib/api";
import { useAsync } from "@/lib/hooks";
import type { ClassSummary, Pupil } from "@/lib/types";
import { ErrorBox, Loading } from "./ui";

interface ClassContextValue {
  klass: ClassSummary;
  pupils: Pupil[];
  reload: () => void;
}

const ClassContext = createContext<ClassContextValue | null>(null);

export function useClass(): ClassContextValue {
  const value = useContext(ClassContext);
  if (!value) throw new Error("useClass must be used inside ClassFrame");
  return value;
}

const TABS = [
  { href: "", label: "Overview" },
  { href: "/pupils", label: "Pupils" },
  { href: "/assignments", label: "Set work" },
  { href: "/sats", label: "SATs practice", years: [6] },
  { href: "/settings", label: "Settings" },
];

export function ClassFrame({ children }: { children: ReactNode }) {
  const { id } = useParams<{ id: string }>();
  const pathname = usePathname();
  const { data, error, reload } = useAsync(() => api().getClass(id), [id]);

  if (error) return <ErrorBox message={error} onRetry={reload} />;
  if (!data) return <Loading />;

  const base = `/classes/${id}`;
  const printing = pathname.endsWith("/login-cards");
  return (
    <ClassContext.Provider value={{ klass: data.class, pupils: data.pupils, reload }}>
      {!printing ? (
        <>
          <div className="crumbs no-print">
            <Link href="/classes">Classes</Link> / {data.class.name}
          </div>
          <div className="page-head">
            <div>
              <h1>
                {data.class.name} <span className="muted" style={{ fontWeight: 500 }}>Year {data.class.yearGroup}</span>
              </h1>
              <p>
                {data.pupils.length} pupils · class code <span className="code">{data.class.classCode}</span>
                {data.class.archived ? " · archived" : ""}
              </p>
            </div>
          </div>
          <nav className="tabs" aria-label="Class">
            {TABS.filter((t) => !t.years || t.years.includes(data.class.yearGroup)).map((tab) => {
              const href = `${base}${tab.href}`;
              const current = tab.href === "" ? pathname === base || pathname.startsWith(`${base}/objectives`) : pathname.startsWith(href);
              return (
                <Link key={tab.href} href={href} aria-current={current ? "page" : undefined}>
                  {tab.label}
                </Link>
              );
            })}
          </nav>
        </>
      ) : null}
      {children}
    </ClassContext.Provider>
  );
}
