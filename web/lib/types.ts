import type { ClassAnalytics, Level, SatsBand } from "./analytics.gen";

export type { Level, SatsBand };

export interface DateRange {
  from: string;
  to: string;
}

export interface Teacher {
  id: string;
  schoolId: string | null;
  displayName: string;
}

export interface School {
  id: string;
  name: string;
  urn: string | null;
}

export interface ClassSummary {
  id: string;
  name: string;
  yearGroup: number;
  classCode: string;
  archived: boolean;
  createdAt: string;
  pupilCount?: number;
}

export interface Pupil {
  id: string;
  displayName: string;
  avatarKey: string;
  locked?: boolean;
}

export interface LoginCard {
  pupilId: string;
  displayName: string;
  avatarKey: string;
  pin: string;
  joinUrl: string;
}

export interface LoginCards {
  classCode: string;
  className: string;
  cards: LoginCard[];
}

export interface Assignment {
  id: string;
  title: string;
  objectiveCodes: string[];
  spellingListId: string | null;
  pupilIds: string[] | null;
  dueDate: string | null;
  createdAt: string;
  assignedPupils: number;
  pupilsStarted: number;
  attempts: number;
  accuracy: number | null;
}

export interface NewAssignment {
  classId: string;
  title: string;
  objectiveCodes: string[];
  spellingListId: string | null;
  pupilIds: string[] | null;
  dueDate: string | null;
}

export type ClassAnalyticsResponse = { class: ClassSummary; range: DateRange } & ClassAnalytics;

export interface ObjectiveDetail {
  class: ClassSummary;
  range: DateRange;
  objective: { code: string; year_group: number; strand: string; title: string; child_title: string; rule: string };
  questions: { questionId: string; prompt: string; attempts: number; accuracy: number | null; pupils: number }[];
  misconceptions: { questionId: string; prompt: string; answerGiven: string; times: number; pupils: number }[];
  pupils: { id: string; displayName: string; avatarKey: string; attempts: number; accuracy: number | null; level: Level }[];
}

export interface PupilProgress {
  class: ClassSummary;
  pupil: Pupil;
  range: DateRange;
  summary: ClassAnalytics["pupils"][number];
  objectives: { code: string; title: string; strand: string; yearGroup: number; attempts: number; recentAccuracy: number | null; level: Level }[];
  daily: { day: string; attempts: number; correct: number }[];
  sessions: { sessionId: string; kind: string; startedAt: string; attempts: number; correct: number; strands: string[] }[];
  spelling: { spellingListId: string; wordsAttempted: number; wordsMastered: number }[];
}

export interface SatsPupil {
  pupilId: string;
  displayName: string;
  avatarKey: string;
  attempts: number;
  accuracy: number | null;
  band: SatsBand;
  strands: Record<string, { attempts: number; accuracy: number | null }>;
}

export interface SatsResponse {
  class: ClassSummary;
  range: DateRange;
  pupils: SatsPupil[];
}

export interface Api {
  readonly demo: boolean;
  me(): Promise<{ teacher: Teacher; school: School | null } | null>;
  saveProfile(input: { displayName: string; schoolName: string; urn: string | null }): Promise<void>;
  listClasses(): Promise<ClassSummary[]>;
  createClass(input: { name: string; yearGroup: number }): Promise<ClassSummary>;
  getClass(id: string): Promise<{ class: ClassSummary; pupils: Pupil[] }>;
  updateClass(id: string, patch: { name?: string; yearGroup?: number; archived?: boolean }): Promise<ClassSummary>;
  deleteClass(id: string): Promise<void>;
  addPupils(classId: string, names: string[]): Promise<LoginCards>;
  loginCards(classId: string, pupilIds?: string[]): Promise<LoginCards>;
  renamePupil(id: string, displayName: string): Promise<void>;
  deletePupil(id: string): Promise<void>;
  listAssignments(classId: string): Promise<Assignment[]>;
  createAssignment(input: NewAssignment): Promise<void>;
  archiveAssignment(id: string): Promise<void>;
  classAnalytics(classId: string, range: DateRange): Promise<ClassAnalyticsResponse>;
  objectiveDetail(classId: string, code: string, range: DateRange): Promise<ObjectiveDetail>;
  pupilProgress(pupilId: string, range: DateRange): Promise<PupilProgress>;
  sats(classId: string, range: DateRange): Promise<SatsResponse>;
  exportCsv(classId: string, range: DateRange): Promise<{ filename: string; blob: Blob }>;
}

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}
