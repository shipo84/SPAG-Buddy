// Copied from backend/supabase/functions/_shared/analytics.ts by backend/scripts/generate-seed.mjs. Do not edit.
// Mastery thresholds are shared with the iOS app (MasteryLevel) and web/lib/mastery.ts.
export const MASTERY = {
  recentWindow: 10,
  minimumAttemptsForSecure: 5,
  secureAccuracy: 0.8,
  supportAccuracy: 0.5,
} as const;

export type Level = "notStarted" | "needsSupport" | "developing" | "secure";

export function masteryLevel(attempts: number, recentAttempts: number, recentCorrect: number): Level {
  if (attempts === 0 || recentAttempts === 0) return "notStarted";
  const accuracy = recentCorrect / recentAttempts;
  if (attempts >= MASTERY.minimumAttemptsForSecure && accuracy >= MASTERY.secureAccuracy) return "secure";
  return accuracy < MASTERY.supportAccuracy && attempts >= 3 ? "needsSupport" : "developing";
}

export interface ObjectiveStatRow {
  pupil_id: string;
  objective_code: string;
  attempts: number;
  correct: number;
  recent_attempts: number;
  recent_correct: number;
  last_answered_at: string;
}

export interface PupilRow {
  id: string;
  display_name: string;
  avatar_key: string;
}

export interface ObjectiveRow {
  code: string;
  year_group: number;
  strand: string;
  title: string;
  child_title: string;
}

export interface Cell {
  pupilId: string;
  objectiveCode: string;
  attempts: number;
  correct: number;
  recentAccuracy: number;
  level: Level;
  lastAnsweredAt: string;
}

export interface ClassAnalytics {
  pupils: { id: string; displayName: string; avatarKey: string; attempts: number; accuracy: number | null; lastActiveAt: string | null; needsSupport: number }[];
  objectives: {
    code: string;
    yearGroup: number;
    strand: string;
    title: string;
    attempts: number;
    accuracy: number | null;
    levels: Record<Level, number>;
  }[];
  cells: Cell[];
  totals: { attempts: number; accuracy: number | null; activePupils: number };
}

// Postgres bigint arrives as a string through PostgREST.
const n = (value: unknown) => Number(value ?? 0);

export function buildClassAnalytics(rows: ObjectiveStatRow[], pupils: PupilRow[], objectives: ObjectiveRow[]): ClassAnalytics {
  const pupilIds = new Set(pupils.map((p) => p.id));
  const cells: Cell[] = rows
    .filter((r) => pupilIds.has(r.pupil_id))
    .map((r) => ({
      pupilId: r.pupil_id,
      objectiveCode: r.objective_code,
      attempts: n(r.attempts),
      correct: n(r.correct),
      recentAccuracy: n(r.recent_attempts) ? n(r.recent_correct) / n(r.recent_attempts) : 0,
      level: masteryLevel(n(r.attempts), n(r.recent_attempts), n(r.recent_correct)),
      lastAnsweredAt: r.last_answered_at,
    }));

  const byPupil = groupBy(cells, (c) => c.pupilId);
  const byObjective = groupBy(cells, (c) => c.objectiveCode);

  const pupilSummaries = pupils
    .map((p) => {
      const mine = byPupil.get(p.id) ?? [];
      const attempts = sum(mine, (c) => c.attempts);
      return {
        id: p.id,
        displayName: p.display_name,
        avatarKey: p.avatar_key,
        attempts,
        accuracy: attempts ? sum(mine, (c) => c.correct) / attempts : null,
        lastActiveAt: mine.reduce<string | null>((latest, c) => (!latest || c.lastAnsweredAt > latest ? c.lastAnsweredAt : latest), null),
        needsSupport: mine.filter((c) => c.level === "needsSupport").length,
      };
    })
    .sort((a, b) => a.displayName.localeCompare(b.displayName, "en-GB"));

  const objectiveSummaries = objectives
    .map((o) => {
      const theirs = byObjective.get(o.code) ?? [];
      const attempts = sum(theirs, (c) => c.attempts);
      const levels: Record<Level, number> = { notStarted: 0, needsSupport: 0, developing: 0, secure: 0 };
      for (const cell of theirs) levels[cell.level]++;
      levels.notStarted = pupils.length - theirs.length;
      return {
        code: o.code,
        yearGroup: o.year_group,
        strand: o.strand,
        title: o.title,
        attempts,
        accuracy: attempts ? sum(theirs, (c) => c.correct) / attempts : null,
        levels,
      };
    })
    .sort((a, b) => b.yearGroup - a.yearGroup || a.strand.localeCompare(b.strand) || a.code.localeCompare(b.code));

  const attempts = sum(cells, (c) => c.attempts);
  return {
    pupils: pupilSummaries,
    objectives: objectiveSummaries,
    cells,
    totals: {
      attempts,
      accuracy: attempts ? sum(cells, (c) => c.correct) / attempts : null,
      activePupils: byPupil.size,
    },
  };
}

export type SatsBand = "onTrack" | "nearly" | "needsSupport" | "notEnoughData";

/** Indicative only: this is not a scaled score. Needs at least 10 SATs-style answers. */
export function satsBand(attempts: number, correct: number): SatsBand {
  if (attempts < 10) return "notEnoughData";
  const accuracy = correct / attempts;
  if (accuracy >= 0.7) return "onTrack";
  if (accuracy >= 0.5) return "nearly";
  return "needsSupport";
}

export interface SatsRow {
  pupil_id: string;
  strand: string;
  attempts: number;
  correct: number;
}

export function buildSatsReadiness(rows: SatsRow[], pupils: PupilRow[]) {
  const byPupil = groupBy(rows, (r) => r.pupil_id);
  return pupils
    .map((p) => {
      const mine = byPupil.get(p.id) ?? [];
      const attempts = sum(mine, (r) => n(r.attempts));
      const correct = sum(mine, (r) => n(r.correct));
      const strands = Object.fromEntries(
        mine.map((r) => [r.strand, { attempts: n(r.attempts), accuracy: n(r.attempts) ? n(r.correct) / n(r.attempts) : null }]),
      );
      return {
        pupilId: p.id,
        displayName: p.display_name,
        avatarKey: p.avatar_key,
        attempts,
        accuracy: attempts ? correct / attempts : null,
        band: satsBand(attempts, correct),
        strands,
      };
    })
    .sort((a, b) => a.displayName.localeCompare(b.displayName, "en-GB"));
}

function groupBy<T>(items: T[], key: (item: T) => string): Map<string, T[]> {
  const map = new Map<string, T[]>();
  for (const item of items) {
    const k = key(item);
    const list = map.get(k);
    if (list) list.push(item);
    else map.set(k, [item]);
  }
  return map;
}

function sum<T>(items: T[], value: (item: T) => number): number {
  return items.reduce((total, item) => total + value(item), 0);
}
