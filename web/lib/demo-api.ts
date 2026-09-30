import {
  buildClassAnalytics,
  buildSatsReadiness,
  masteryLevel,
  type ObjectiveRow,
  type ObjectiveStatRow,
  type PupilRow,
  type SatsRow,
} from "./analytics.gen";
import { generateClassCode, generatePin, joinUrl, pickUnusedAvatar } from "./codes.gen";
import { AVATARS, OBJECTIVES, QUESTIONS, SPELLING_LISTS, objective, spellingListsForYear } from "./content";
import { toCsv } from "./csv.gen";
import { slugFilename } from "./format";
import { type Api, ApiError, type Assignment, type ClassSummary, type DateRange, type LoginCards, type NewAssignment } from "./types";

/** Must match SpellingQuestionFactory.slug in the iOS app and slug() in backend/scripts/generate-seed.mjs. */
export function slug(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

interface DemoQuestion {
  id: string;
  objectiveCode: string;
  strand: string;
  prompt: string;
  choices: string[] | null;
  answers: string[];
  satsStyle: boolean;
  spellingListId: string | null;
}

interface DemoPupil {
  id: string;
  classId: string;
  displayName: string;
  avatarKey: string;
}

interface DemoAttempt {
  pupilId: string;
  classId: string;
  questionId: string;
  objectiveCode: string;
  strand: string;
  correct: boolean;
  answerGiven: string;
  timeTakenMs: number;
  hintUsed: boolean;
  sessionId: string;
  sessionKind: string;
  assignmentId: string | null;
  answeredAt: string;
}

interface DemoAssignment extends NewAssignment {
  id: string;
  createdAt: string;
  archived: boolean;
}

interface DemoClass {
  id: string;
  name: string;
  yearGroup: number;
  classCode: string;
  archivedAt: string | null;
  createdAt: string;
}

const FIRST_NAMES = [
  "Amara", "Ben", "Chloe", "Dev", "Ella", "Finn", "Grace", "Harry", "Isla", "Jayden", "Kai", "Layla", "Mohammed", "Nia",
  "Oliver", "Priya", "Quinn", "Rosie", "Sam", "Tariq", "Una", "Victor", "Willow", "Xander", "Yusuf", "Zara", "Alfie",
  "Bea", "Callum", "Darcy",
];

/** Small deterministic PRNG so the demo looks the same on every visit. */
function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function demoUuid(random: () => number): string {
  const hex = Array.from({ length: 32 }, () => Math.floor(random() * 16).toString(16)).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-a${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

function misspell(word: string, random: () => number): string {
  if (word.length < 3) return word + word.at(-1);
  const i = 1 + Math.floor(random() * (word.length - 2));
  const options = [
    word.slice(0, i) + word.slice(i + 1),
    word.slice(0, i) + word[i] + word.slice(i),
    word.replace(/ie/, "ei").replace(/ough/, "uff").replace(/tion/, "shun"),
  ].filter((w) => w !== word);
  return options[Math.floor(random() * options.length)] ?? word + "e";
}

export function buildQuestionBank(): DemoQuestion[] {
  const written: DemoQuestion[] = QUESTIONS.map((q) => ({
    id: q.id,
    objectiveCode: q.objectiveCode,
    strand: objective(q.objectiveCode)?.strand ?? "grammar",
    prompt: q.prompt,
    choices: q.choices,
    answers: q.answers,
    satsStyle: q.satsStyle,
    spellingListId: null,
  }));
  const spelling: DemoQuestion[] = SPELLING_LISTS.flatMap((list) =>
    list.words.map((word) => ({
      id: `spell-${list.id}-${slug(word)}`,
      objectiveCode: list.objectiveCode,
      strand: "spelling",
      prompt: `Spell: ${word}`,
      choices: null,
      answers: [word],
      satsStyle: false,
      spellingListId: list.id,
    })),
  );
  return [...written, ...spelling];
}

export interface DemoData {
  teacher: { id: string; schoolId: string; displayName: string };
  school: { id: string; name: string; urn: string | null };
  classes: DemoClass[];
  pupils: DemoPupil[];
  attempts: DemoAttempt[];
  assignments: DemoAssignment[];
  questions: Map<string, DemoQuestion>;
}

export function buildDemoData(now = new Date(), seed = 20260930): DemoData {
  const random = mulberry32(seed);
  const bank = buildQuestionBank();
  const questions = new Map(bank.map((q) => [q.id, q]));
  const day = 86_400_000;

  const classes: DemoClass[] = [
    { id: demoUuid(random), name: "Kestrels", yearGroup: 4, classCode: "KES4TR", archivedAt: null, createdAt: new Date(now.getTime() - 50 * day).toISOString() },
    { id: demoUuid(random), name: "Owls", yearGroup: 6, classCode: "WLS6YX", archivedAt: null, createdAt: new Date(now.getTime() - 50 * day).toISOString() },
  ];

  const pupils: DemoPupil[] = [];
  const attempts: DemoAttempt[] = [];
  const assignments: DemoAssignment[] = [];

  for (const [classIndex, klass] of classes.entries()) {
    const size = classIndex === 0 ? 26 : 24;
    const avatars = [...AVATARS].sort(() => random() - 0.5);
    const pool = bank.filter((q) => {
      const year = objective(q.objectiveCode)?.yearGroup ?? 0;
      if (q.spellingListId) return spellingListsForYear(klass.yearGroup).some((l) => l.id === q.spellingListId);
      return year === klass.yearGroup || year === klass.yearGroup - 1;
    });
    const hardObjectives = new Set(
      [...new Set(pool.map((q) => q.objectiveCode))].filter(() => random() < 0.3),
    );

    const assignment: DemoAssignment = {
      id: demoUuid(random),
      classId: klass.id,
      title: klass.yearGroup === 6 ? "SATs warm-up" : "Apostrophes this week",
      objectiveCodes: [...new Set(pool.filter((q) => !q.spellingListId).map((q) => q.objectiveCode))].slice(0, 2),
      spellingListId: null,
      pupilIds: null,
      dueDate: new Date(now.getTime() + 4 * day).toISOString().slice(0, 10),
      createdAt: new Date(now.getTime() - 3 * day).toISOString(),
      archived: false,
    };
    assignments.push(assignment);

    for (let p = 0; p < size; p++) {
      const pupil: DemoPupil = {
        id: demoUuid(random),
        classId: klass.id,
        displayName: `${FIRST_NAMES[(p + classIndex * 7) % FIRST_NAMES.length]} ${String.fromCharCode(65 + Math.floor(random() * 26))}`,
        avatarKey: avatars[p].key,
      };
      pupils.push(pupil);
      if (!pool.length) continue;

      const ability = 0.35 + random() * 0.6;
      const engagement = p % 9 === 8 ? 0.05 : 0.25 + random() * 0.55;
      for (let d = 45; d >= 0; d--) {
        if (random() > engagement) continue;
        const sessionStart = now.getTime() - d * day + (9 + random() * 6) * 3_600_000 - 24 * 3_600_000;
        if (sessionStart > now.getTime()) continue;
        const onAssignment = d <= 3 && random() < 0.6 && assignment.objectiveCodes.length > 0;
        const sats = !onAssignment && klass.yearGroup === 6 && random() < 0.4;
        const sessionPool = onAssignment
          ? pool.filter((q) => assignment.objectiveCodes.includes(q.objectiveCode))
          : sats
            ? pool.filter((q) => q.satsStyle)
            : pool;
        const source = sessionPool.length ? sessionPool : pool;
        const kind = onAssignment ? "assignment" : sats ? "satsPractice" : random() < 0.7 ? "daily" : "spellingList";
        const sessionId = demoUuid(random);
        const length = sats ? 20 : 10;

        for (let i = 0; i < length; i++) {
          const question = source[Math.floor(random() * source.length)];
          const learning = (45 - d) / 45 * 0.15;
          const difficulty = hardObjectives.has(question.objectiveCode) ? 0.3 : 0;
          const correct = random() < Math.min(0.97, Math.max(0.05, ability + learning - difficulty));
          let answerGiven = question.answers[0];
          if (!correct) {
            const wrong = question.choices?.filter((c) => !question.answers.includes(c)) ?? [];
            answerGiven = wrong.length
              ? wrong[Math.floor(random() * Math.min(2, wrong.length))]
              : question.spellingListId
                ? misspell(question.answers[0], random)
                : "";
          }
          attempts.push({
            pupilId: pupil.id,
            classId: klass.id,
            questionId: question.id,
            objectiveCode: question.objectiveCode,
            strand: question.strand,
            correct,
            answerGiven,
            timeTakenMs: Math.round(4000 + random() * 20000),
            hintUsed: !correct && random() < 0.3,
            sessionId,
            sessionKind: kind,
            assignmentId: onAssignment ? assignment.id : null,
            answeredAt: new Date(sessionStart + i * 25_000).toISOString(),
          });
        }
      }
    }
  }

  const schoolId = demoUuid(random);
  return {
    teacher: { id: demoUuid(random), schoolId, displayName: "Ms Patel" },
    school: { id: schoolId, name: "Oakfield Primary (demo)", urn: null },
    classes,
    pupils,
    attempts,
    assignments,
    questions,
  };
}

const notFound = (what: string) => new ApiError(404, "not_found", `${what} not found`);
const toRow = (p: DemoPupil): PupilRow => ({ id: p.id, display_name: p.displayName, avatar_key: p.avatarKey });

/** An in-memory stand-in for the API that follows the same rules, so the dashboard can be explored with made-up pupils. */
export function createDemoApi(data: DemoData = buildDemoData(), latencyMs = 120): Api {
  const wait = () => new Promise((resolve) => setTimeout(resolve, latencyMs));
  let counter = 0;
  const newId = () => `00000000-0000-4000-8000-${String(++counter).padStart(12, "0")}`;

  const findClass = (id: string) => {
    const klass = data.classes.find((c) => c.id === id);
    if (!klass) throw notFound("Class");
    return klass;
  };
  const classPupils = (classId: string) =>
    data.pupils.filter((p) => p.classId === classId).sort((a, b) => a.displayName.localeCompare(b.displayName, "en-GB"));
  const summary = (c: DemoClass, withCount = true): ClassSummary => ({
    id: c.id,
    name: c.name,
    yearGroup: c.yearGroup,
    classCode: c.classCode,
    archived: c.archivedAt !== null,
    createdAt: c.createdAt,
    ...(withCount ? { pupilCount: classPupils(c.id).length } : {}),
  });
  const inRange = (range: DateRange) => (a: DemoAttempt) => a.answeredAt >= range.from && a.answeredAt < range.to;

  function objectiveStats(classId: string, range: DateRange): ObjectiveStatRow[] {
    const groups = new Map<string, DemoAttempt[]>();
    for (const a of data.attempts.filter((a) => a.classId === classId).filter(inRange(range))) {
      const key = `${a.pupilId}|${a.objectiveCode}`;
      const list = groups.get(key);
      if (list) list.push(a);
      else groups.set(key, [a]);
    }
    return [...groups.values()].map((list) => {
      const sorted = [...list].sort((a, b) => b.answeredAt.localeCompare(a.answeredAt));
      const recent = sorted.slice(0, 10);
      return {
        pupil_id: list[0].pupilId,
        objective_code: list[0].objectiveCode,
        attempts: list.length,
        correct: list.filter((a) => a.correct).length,
        recent_attempts: recent.length,
        recent_correct: recent.filter((a) => a.correct).length,
        last_answered_at: sorted[0].answeredAt,
      };
    });
  }

  function classObjectives(yearGroup: number, extraCodes: string[]): ObjectiveRow[] {
    const years = new Set([Math.max(1, yearGroup - 1), yearGroup]);
    const codes = new Set(extraCodes);
    return OBJECTIVES.filter((o) => years.has(o.yearGroup) || codes.has(o.code)).map((o) => ({
      code: o.code,
      year_group: o.yearGroup,
      strand: o.strand,
      title: o.title,
      child_title: o.childTitle,
    }));
  }

  function issueCards(klass: DemoClass, pupils: DemoPupil[]): LoginCards {
    return {
      classCode: klass.classCode,
      className: klass.name,
      cards: pupils.map((p) => {
        const pin = generatePin();
        return { pupilId: p.id, displayName: p.displayName, avatarKey: p.avatarKey, pin, joinUrl: joinUrl(klass.classCode, p.avatarKey, pin) };
      }),
    };
  }

  function validClassName(name: string) {
    const trimmed = name.trim();
    if (!trimmed || trimmed.length > 60) throw new ApiError(400, "bad_request", "name must be 1 to 60 characters");
    return trimmed;
  }

  /** Same rule as pupilName() in the API: first names or nicknames only. */
  function validName(value: string) {
    const name = value.trim().replace(/\s+/g, " ");
    if (name.length < 1 || name.length > 30) throw new ApiError(400, "bad_request", "Pupil names must be 1 to 30 characters");
    if (/[@\d]/.test(name)) throw new ApiError(400, "bad_request", `"${name}" should be a first name or nickname only`);
    return name;
  }

  return {
    demo: true,
    async me() {
      await wait();
      return { teacher: data.teacher, school: data.school };
    },
    async saveProfile(input) {
      await wait();
      data.teacher.displayName = input.displayName;
      data.school.name = input.schoolName;
      data.school.urn = input.urn;
    },
    async listClasses() {
      await wait();
      return [...data.classes].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).map((c) => summary(c));
    },
    async createClass(input) {
      await wait();
      const klass: DemoClass = {
        id: newId(),
        name: validClassName(input.name),
        yearGroup: input.yearGroup,
        classCode: generateClassCode(),
        archivedAt: null,
        createdAt: new Date().toISOString(),
      };
      data.classes.push(klass);
      return summary(klass);
    },
    async getClass(id) {
      await wait();
      const klass = findClass(id);
      return { class: summary(klass), pupils: classPupils(id).map((p) => ({ id: p.id, displayName: p.displayName, avatarKey: p.avatarKey, locked: false })) };
    },
    async updateClass(id, patch) {
      await wait();
      const klass = findClass(id);
      if (patch.name !== undefined) klass.name = validClassName(patch.name);
      if (patch.yearGroup !== undefined) klass.yearGroup = patch.yearGroup;
      if (patch.archived !== undefined) klass.archivedAt = patch.archived ? new Date().toISOString() : null;
      return summary(klass, false);
    },
    async deleteClass(id) {
      await wait();
      findClass(id);
      data.classes = data.classes.filter((c) => c.id !== id);
      data.pupils = data.pupils.filter((p) => p.classId !== id);
      data.attempts = data.attempts.filter((a) => a.classId !== id);
      data.assignments = data.assignments.filter((a) => a.classId !== id);
    },
    async addPupils(classId, names) {
      await wait();
      const klass = findClass(classId);
      const existing = classPupils(classId);
      const cleaned = names.map(validName);
      if (existing.length + cleaned.length > AVATARS.length) {
        throw new ApiError(400, "bad_request", `A class can have up to ${AVATARS.length} pupils`);
      }
      const used = new Set(existing.map((p) => p.avatarKey));
      const created: DemoPupil[] = [];
      for (const displayName of cleaned) {
        const avatarKey = pickUnusedAvatar(AVATARS.map((a) => a.key), used);
        if (!avatarKey) break;
        used.add(avatarKey);
        const pupil = { id: newId(), classId, displayName, avatarKey };
        data.pupils.push(pupil);
        created.push(pupil);
      }
      return issueCards(klass, created);
    },
    async loginCards(classId, pupilIds) {
      await wait();
      const klass = findClass(classId);
      let pupils = classPupils(classId);
      if (pupilIds?.length) pupils = pupils.filter((p) => pupilIds.includes(p.id));
      return issueCards(klass, pupils);
    },
    async renamePupil(id, displayName) {
      await wait();
      const pupil = data.pupils.find((p) => p.id === id);
      if (!pupil) throw notFound("Pupil");
      pupil.displayName = validName(displayName);
    },
    async deletePupil(id) {
      await wait();
      if (!data.pupils.some((p) => p.id === id)) throw notFound("Pupil");
      data.pupils = data.pupils.filter((p) => p.id !== id);
      data.attempts = data.attempts.filter((a) => a.pupilId !== id);
    },
    async listAssignments(classId) {
      await wait();
      findClass(classId);
      const pupilCount = classPupils(classId).length;
      return data.assignments
        .filter((a) => a.classId === classId && !a.archived)
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
        .map((a): Assignment => {
          const mine = data.attempts.filter((t) => t.assignmentId === a.id);
          return {
            id: a.id,
            title: a.title,
            objectiveCodes: a.objectiveCodes,
            spellingListId: a.spellingListId,
            pupilIds: a.pupilIds,
            dueDate: a.dueDate,
            createdAt: a.createdAt,
            assignedPupils: a.pupilIds?.length ?? pupilCount,
            pupilsStarted: new Set(mine.map((t) => t.pupilId)).size,
            attempts: mine.length,
            accuracy: mine.length ? mine.filter((t) => t.correct).length / mine.length : null,
          };
        });
    },
    async createAssignment(input) {
      await wait();
      findClass(input.classId);
      if (!input.title.trim()) throw new ApiError(400, "bad_request", "Give the assignment a title");
      if (!input.objectiveCodes.length && !input.spellingListId) throw new ApiError(400, "bad_request", "Choose at least one skill or a spelling list");
      data.assignments.push({ ...input, title: input.title.trim(), id: newId(), createdAt: new Date().toISOString(), archived: false });
    },
    async archiveAssignment(id) {
      await wait();
      const assignment = data.assignments.find((a) => a.id === id);
      if (!assignment) throw notFound("Assignment");
      assignment.archived = true;
    },
    async classAnalytics(classId, range) {
      await wait();
      const klass = findClass(classId);
      const stats = objectiveStats(classId, range);
      const pupils = classPupils(classId).map(toRow);
      const objectives = classObjectives(klass.yearGroup, stats.map((s) => s.objective_code));
      return { class: summary(klass), range, ...buildClassAnalytics(stats, pupils, objectives) };
    },
    async objectiveDetail(classId, code, range) {
      await wait();
      const klass = findClass(classId);
      const info = objective(code);
      if (!info) throw notFound("Objective");
      const mineAttempts = data.attempts.filter((a) => a.classId === classId && a.objectiveCode === code).filter(inRange(range));

      const byQuestion = new Map<string, DemoAttempt[]>();
      for (const a of mineAttempts) byQuestion.set(a.questionId, [...(byQuestion.get(a.questionId) ?? []), a]);
      const questions = [...byQuestion.entries()]
        .map(([questionId, list]) => ({
          questionId,
          prompt: data.questions.get(questionId)?.prompt ?? questionId,
          attempts: list.length,
          accuracy: list.filter((a) => a.correct).length / list.length,
          pupils: new Set(list.map((a) => a.pupilId)).size,
        }))
        .sort((a, b) => a.accuracy - b.accuracy || b.attempts - a.attempts);

      const wrong = new Map<string, DemoAttempt[]>();
      for (const a of mineAttempts.filter((a) => !a.correct && a.answerGiven)) {
        const key = `${a.questionId}\u0000${a.answerGiven}`;
        wrong.set(key, [...(wrong.get(key) ?? []), a]);
      }
      const misconceptions = [...wrong.values()]
        .map((list) => ({
          questionId: list[0].questionId,
          prompt: data.questions.get(list[0].questionId)?.prompt ?? list[0].questionId,
          answerGiven: list[0].answerGiven,
          times: list.length,
          pupils: new Set(list.map((a) => a.pupilId)).size,
        }))
        .sort((a, b) => b.pupils - a.pupils || b.times - a.times)
        .slice(0, 10);

      const stats = new Map(objectiveStats(classId, range).filter((s) => s.objective_code === code).map((s) => [s.pupil_id, s]));
      return {
        class: summary(klass, false),
        range,
        objective: { code: info.code, year_group: info.yearGroup, strand: info.strand, title: info.title, child_title: info.childTitle, rule: info.rule },
        questions,
        misconceptions,
        pupils: classPupils(classId).map((p) => {
          const s = stats.get(p.id);
          return {
            id: p.id,
            displayName: p.displayName,
            avatarKey: p.avatarKey,
            attempts: s?.attempts ?? 0,
            accuracy: s ? s.correct / s.attempts : null,
            level: masteryLevel(s?.attempts ?? 0, s?.recent_attempts ?? 0, s?.recent_correct ?? 0),
          };
        }),
      };
    },
    async pupilProgress(pupilId, range) {
      await wait();
      const pupil = data.pupils.find((p) => p.id === pupilId);
      if (!pupil) throw notFound("Pupil");
      const klass = findClass(pupil.classId);
      const all = data.attempts.filter((a) => a.pupilId === pupilId);
      const inWindow = all.filter(inRange(range));

      const days = new Map<string, { attempts: number; correct: number }>();
      const london = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/London" });
      for (const a of inWindow) {
        const key = london.format(new Date(a.answeredAt));
        const entry = days.get(key) ?? { attempts: 0, correct: 0 };
        entry.attempts++;
        if (a.correct) entry.correct++;
        days.set(key, entry);
      }

      const sessions = new Map<string, DemoAttempt[]>();
      for (const a of all) sessions.set(a.sessionId, [...(sessions.get(a.sessionId) ?? []), a]);

      const latest = new Map<string, DemoAttempt>();
      for (const a of all) {
        const current = latest.get(a.questionId);
        if (!current || a.answeredAt > current.answeredAt) latest.set(a.questionId, a);
      }
      const spelling = new Map<string, { attempted: number; mastered: number }>();
      for (const a of latest.values()) {
        const listId = data.questions.get(a.questionId)?.spellingListId;
        if (!listId) continue;
        const entry = spelling.get(listId) ?? { attempted: 0, mastered: 0 };
        entry.attempted++;
        if (a.correct) entry.mastered++;
        spelling.set(listId, entry);
      }

      const stats = objectiveStats(klass.id, range).filter((s) => s.pupil_id === pupilId);
      const analytics = buildClassAnalytics(stats, [toRow(pupil)], classObjectives(klass.yearGroup, stats.map((s) => s.objective_code)));

      return {
        class: summary(klass, false),
        pupil: { id: pupil.id, displayName: pupil.displayName, avatarKey: pupil.avatarKey },
        range,
        summary: analytics.pupils[0],
        objectives: analytics.objectives.map((o) => {
          const cell = analytics.cells.find((c) => c.objectiveCode === o.code);
          return { code: o.code, title: o.title, strand: o.strand, yearGroup: o.yearGroup, attempts: cell?.attempts ?? 0, recentAccuracy: cell?.recentAccuracy ?? null, level: cell?.level ?? "notStarted" };
        }),
        daily: [...days.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([day, v]) => ({ day, ...v })),
        sessions: [...sessions.entries()]
          .map(([sessionId, list]) => ({
            sessionId,
            kind: list[0].sessionKind,
            startedAt: list.reduce((min, a) => (a.answeredAt < min ? a.answeredAt : min), list[0].answeredAt),
            attempts: list.length,
            correct: list.filter((a) => a.correct).length,
            strands: [...new Set(list.map((a) => a.strand))].sort(),
          }))
          .sort((a, b) => b.startedAt.localeCompare(a.startedAt))
          .slice(0, 20),
        spelling: [...spelling.entries()].map(([spellingListId, v]) => ({ spellingListId, wordsAttempted: v.attempted, wordsMastered: v.mastered })),
      };
    },
    async sats(classId, range) {
      await wait();
      const klass = findClass(classId);
      const groups = new Map<string, SatsRow>();
      for (const a of data.attempts.filter((a) => a.classId === classId && data.questions.get(a.questionId)?.satsStyle).filter(inRange(range))) {
        const key = `${a.pupilId}|${a.strand}`;
        const row = groups.get(key) ?? { pupil_id: a.pupilId, strand: a.strand, attempts: 0, correct: 0 };
        row.attempts++;
        if (a.correct) row.correct++;
        groups.set(key, row);
      }
      return { class: summary(klass), range, pupils: buildSatsReadiness([...groups.values()], classPupils(classId).map(toRow)) };
    },
    async exportCsv(classId, range) {
      await wait();
      const klass = findClass(classId);
      const names = new Map(data.pupils.map((p) => [p.id, p.displayName]));
      const rows = data.attempts
        .filter((a) => a.classId === classId)
        .filter(inRange(range))
        .sort((a, b) => a.answeredAt.localeCompare(b.answeredAt))
        .map((a) => [
          names.get(a.pupilId) ?? "(deleted)",
          a.answeredAt,
          a.objectiveCode,
          a.strand,
          a.questionId,
          a.correct ? "yes" : "no",
          a.answerGiven,
          Math.round(a.timeTakenMs / 1000),
          a.hintUsed ? "yes" : "no",
          a.sessionKind,
        ]);
      const csv = toCsv(["Pupil", "Answered at", "Objective", "Strand", "Question", "Correct", "Answer given", "Seconds", "Hint used", "Session type"], rows);
      return {
        filename: `${slugFilename(klass.name)}-${range.from.slice(0, 10)}-to-${range.to.slice(0, 10)}.csv`,
        blob: new Blob([csv], { type: "text/csv;charset=utf-8" }),
      };
    },
  };
}
