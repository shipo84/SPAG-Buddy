import content from "./content.gen.json";

export interface ObjectiveInfo {
  code: string;
  yearGroup: number;
  strand: string;
  title: string;
  childTitle: string;
  rule: string;
}

export interface QuestionInfo {
  id: string;
  objectiveCode: string;
  type: string;
  prompt: string;
  choices: string[] | null;
  answers: string[];
  satsStyle: boolean;
}

export interface SpellingListInfo {
  id: string;
  title: string;
  objectiveCode: string;
  yearGroups: number[];
  wordCount: number;
  words: string[];
}

export const CONTENT_VERSION: string = content.contentVersion;
export const OBJECTIVES = content.objectives as ObjectiveInfo[];
export const QUESTIONS = content.questions as QuestionInfo[];
export const SPELLING_LISTS = content.spellingLists as SpellingListInfo[];
export const AVATARS = content.avatars as { key: string; emoji: string; name: string }[];

const avatarByKey = new Map(AVATARS.map((a) => [a.key, a]));
const objectiveByCode = new Map(OBJECTIVES.map((o) => [o.code, o]));
const listById = new Map(SPELLING_LISTS.map((l) => [l.id, l]));

export const STRANDS: Record<string, string> = {
  spelling: "Spelling",
  punctuation: "Punctuation",
  grammar: "Grammar",
  vocabulary: "Vocabulary",
};

export const strandName = (strand: string) => STRANDS[strand] ?? strand;
export const avatar = (key: string) => avatarByKey.get(key) ?? { key, emoji: "🙂", name: key };
export const objective = (code: string) => objectiveByCode.get(code);
export const objectiveTitle = (code: string) => objectiveByCode.get(code)?.title ?? code;
export const spellingList = (id: string) => listById.get(id);

/** Objectives a class would normally be taught: its own year and the year below for catch-up. */
export function objectivesForYear(yearGroup: number): ObjectiveInfo[] {
  return OBJECTIVES.filter((o) => o.yearGroup === yearGroup || o.yearGroup === yearGroup - 1).sort(
    (a, b) => b.yearGroup - a.yearGroup || a.strand.localeCompare(b.strand) || a.title.localeCompare(b.title),
  );
}

export function spellingListsForYear(yearGroup: number): SpellingListInfo[] {
  return SPELLING_LISTS.filter((l) => l.yearGroups.includes(yearGroup) || l.yearGroups.includes(yearGroup - 1));
}

/** Keys match SessionMode.kind in the iOS app. */
export const SESSION_KINDS: Record<string, string> = {
  daily: "Daily practice",
  strand: "Topic practice",
  objective: "Skill practice",
  "spelling-list": "Spelling list",
  assignment: "Set work",
  sats: "SATs practice",
};
