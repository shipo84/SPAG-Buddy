import type { ClassAnalytics } from "./analytics.gen";

type ObjectiveSummary = ClassAnalytics["objectives"][number];
type PupilSummary = ClassAnalytics["pupils"][number];

/** Skills where at least two pupils need support, or the class gets fewer than 60% right. Hardest first. */
export function focusObjectives(data: Pick<ClassAnalytics, "objectives">, limit = 5): ObjectiveSummary[] {
  return data.objectives
    .filter((o) => o.attempts > 0 && (o.levels.needsSupport >= 2 || (o.accuracy ?? 1) < 0.6))
    .sort((a, b) => b.levels.needsSupport - a.levels.needsSupport || (a.accuracy ?? 1) - (b.accuracy ?? 1))
    .slice(0, limit);
}

export const INACTIVE_DAYS = 7;

/** Pupils who have not practised for a week, or who need support on two or more skills. */
export function pupilsToCheckIn(
  data: Pick<ClassAnalytics, "pupils">,
  now = new Date(),
  limit = 8,
): { pupil: PupilSummary; reason: string; priority: number }[] {
  const cutoff = now.getTime() - INACTIVE_DAYS * 86_400_000;
  return data.pupils
    .flatMap((pupil) => {
      if (!pupil.lastActiveAt) return [{ pupil, reason: "No practice in this date range", priority: 3 }];
      if (pupil.needsSupport >= 2) return [{ pupil, reason: `Needs support on ${pupil.needsSupport} skills`, priority: 2 + pupil.needsSupport / 100 }];
      if (new Date(pupil.lastActiveAt).getTime() < cutoff) return [{ pupil, reason: "Not practised for over a week", priority: 1 }];
      return [];
    })
    .sort((a, b) => b.priority - a.priority || a.pupil.displayName.localeCompare(b.pupil.displayName, "en-GB"))
    .slice(0, limit);
}
