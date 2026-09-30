"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Loading } from "@/components/ui";
import { useSession } from "@/lib/hooks";

export default function Home() {
  const router = useRouter();
  const { state } = useSession();
  useEffect(() => {
    if (state === "signedIn") router.replace("/classes");
    if (state === "signedOut") router.replace("/sign-in");
  }, [state, router]);
  return (
    <main className="page">
      <Loading />
    </main>
  );
}
