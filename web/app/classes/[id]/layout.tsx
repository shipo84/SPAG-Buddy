"use client";

import type { ReactNode } from "react";
import { ClassFrame } from "@/components/ClassContext";
import { TeacherShell } from "@/components/TeacherShell";

export default function ClassLayout({ children }: { children: ReactNode }) {
  return (
    <TeacherShell>
      <ClassFrame>{children}</ClassFrame>
    </TeacherShell>
  );
}
