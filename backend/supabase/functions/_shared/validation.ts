import { badRequest } from "./http.ts";

type Json = Record<string, unknown>;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const SESSION_KINDS = new Set(["daily", "strand", "objective", "spelling-list", "assignment", "sats"]);

export const MAX_ATTEMPTS_PER_BATCH = 200;
export const MAX_PUPILS_PER_REQUEST = 40;

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID.test(value);
}

function object(body: unknown): Json {
  if (!body || typeof body !== "object" || Array.isArray(body)) throw badRequest("Body must be a JSON object");
  return body as Json;
}

function text(body: Json, key: string, { min = 1, max = 200 } = {}): string {
  const value = body[key];
  if (typeof value !== "string") throw badRequest(`${key} must be text`);
  const trimmed = value.trim().replace(/\s+/g, " ");
  if (trimmed.length < min || trimmed.length > max) throw badRequest(`${key} must be ${min} to ${max} characters`);
  return trimmed;
}

function optionalText(body: Json, key: string, max = 200): string | null {
  return body[key] === undefined || body[key] === null || body[key] === "" ? null : text(body, key, { max });
}

function yearGroup(body: Json): number {
  const value = body.yearGroup;
  if (typeof value !== "number" || !Number.isInteger(value) || value < 1 || value > 6) {
    throw badRequest("yearGroup must be 1 to 6");
  }
  return value;
}

/** First names or nicknames only: rejects things that look like surnames, emails or numbers. */
export function pupilName(value: unknown): string {
  if (typeof value !== "string") throw badRequest("Pupil names must be text");
  const name = value.trim().replace(/\s+/g, " ");
  if (name.length < 1 || name.length > 30) throw badRequest("Pupil names must be 1 to 30 characters");
  if (/[@\d]/.test(name)) throw badRequest(`"${name}" should be a first name or nickname only`);
  return name;
}

export interface JoinRequest {
  classCode: string;
  avatarKey: string;
  pin: string;
}

export function parseJoin(body: unknown): JoinRequest {
  const b = object(body);
  const classCode = text(b, "classCode", { min: 6, max: 6 }).toUpperCase();
  const avatarKey = text(b, "avatarKey", { max: 30 });
  const pin = text(b, "pin", { min: 4, max: 4 });
  if (!/^\d{4}$/.test(pin)) throw badRequest("pin must be 4 digits");
  return { classCode, avatarKey, pin };
}

export interface AttemptInput {
  clientAttemptId: string;
  questionId: string;
  correct: boolean;
  answerGiven: string;
  timeTakenMs: number;
  hintUsed: boolean;
  sessionId: string;
  sessionKind: string;
  assignmentId: string | null;
  answeredAt: string;
}

export interface Rejected {
  clientAttemptId: string;
  reason: string;
}

/** Validates a batch. Bad items are rejected individually so one bad answer cannot block a whole upload. */
export function parseAttempts(body: unknown, now = new Date()): { valid: AttemptInput[]; rejected: Rejected[] } {
  const b = object(body);
  if (!Array.isArray(b.attempts)) throw badRequest("attempts must be a list");
  if (b.attempts.length > MAX_ATTEMPTS_PER_BATCH) throw badRequest(`Send at most ${MAX_ATTEMPTS_PER_BATCH} attempts at a time`);

  const valid: AttemptInput[] = [];
  const rejected: Rejected[] = [];
  const seen = new Set<string>();
  const earliest = now.getTime() - 400 * 24 * 3600 * 1000;

  for (const raw of b.attempts) {
    const item = (raw && typeof raw === "object" ? raw : {}) as Json;
    const id = item.clientAttemptId;
    if (!isUuid(id)) {
      continue;
    }
    const reject = (reason: string) => rejected.push({ clientAttemptId: id, reason });
    if (seen.has(id)) continue;
    seen.add(id);

    if (typeof item.questionId !== "string" || item.questionId.length === 0 || item.questionId.length > 120) {
      reject("invalid_question");
      continue;
    }
    if (typeof item.correct !== "boolean") {
      reject("invalid_correct");
      continue;
    }
    if (!isUuid(item.sessionId)) {
      reject("invalid_session");
      continue;
    }
    const answeredAt = typeof item.answeredAt === "string" ? Date.parse(item.answeredAt) : NaN;
    if (Number.isNaN(answeredAt) || answeredAt < earliest) {
      reject("invalid_time");
      continue;
    }

    const answerGiven = typeof item.answerGiven === "string" ? item.answerGiven.slice(0, 200) : "";
    const time = typeof item.timeTakenMs === "number" && Number.isFinite(item.timeTakenMs) ? item.timeTakenMs : 0;

    valid.push({
      clientAttemptId: id,
      questionId: item.questionId,
      correct: item.correct,
      answerGiven,
      timeTakenMs: Math.min(Math.max(0, Math.round(time)), 3_600_000),
      hintUsed: item.hintUsed === true,
      sessionId: item.sessionId,
      sessionKind: typeof item.sessionKind === "string" && SESSION_KINDS.has(item.sessionKind) ? item.sessionKind : "daily",
      assignmentId: isUuid(item.assignmentId) ? item.assignmentId : null,
      // Device clocks can be wrong; never store a time in the future.
      answeredAt: new Date(Math.min(answeredAt, now.getTime())).toISOString(),
    });
  }
  return { valid, rejected };
}

export function parseCreateClass(body: unknown): { name: string; yearGroup: number } {
  const b = object(body);
  return { name: text(b, "name", { max: 60 }), yearGroup: yearGroup(b) };
}

export function parseUpdateClass(body: unknown): { name?: string; yearGroup?: number; archived?: boolean } {
  const b = object(body);
  const result: { name?: string; yearGroup?: number; archived?: boolean } = {};
  if (b.name !== undefined) result.name = text(b, "name", { max: 60 });
  if (b.yearGroup !== undefined) result.yearGroup = yearGroup(b);
  if (b.archived !== undefined) {
    if (typeof b.archived !== "boolean") throw badRequest("archived must be true or false");
    result.archived = b.archived;
  }
  return result;
}

export function parseAddPupils(body: unknown): string[] {
  const b = object(body);
  if (!Array.isArray(b.names) || b.names.length === 0) throw badRequest("names must be a non-empty list");
  if (b.names.length > MAX_PUPILS_PER_REQUEST) throw badRequest(`Add at most ${MAX_PUPILS_PER_REQUEST} pupils at a time`);
  return b.names.map(pupilName);
}

export function parseTeacherProfile(body: unknown): { displayName: string; schoolName: string; urn: string | null } {
  const b = object(body);
  const urn = optionalText(b, "urn", 7);
  if (urn && !/^\d{6,7}$/.test(urn)) throw badRequest("URN must be 6 or 7 digits");
  return { displayName: text(b, "displayName", { max: 80 }), schoolName: text(b, "schoolName", { max: 120 }), urn };
}

export interface AssignmentInput {
  classId: string;
  title: string;
  objectiveCodes: string[];
  spellingListId: string | null;
  pupilIds: string[] | null;
  dueDate: string | null;
}

export function parseAssignment(body: unknown): AssignmentInput {
  const b = object(body);
  if (!isUuid(b.classId)) throw badRequest("classId is required");
  const objectiveCodes = Array.isArray(b.objectiveCodes)
    ? [...new Set(b.objectiveCodes.filter((c): c is string => typeof c === "string" && c.length <= 80))]
    : [];
  const spellingListId = optionalText(b, "spellingListId", 80);
  if (objectiveCodes.length === 0 && !spellingListId) throw badRequest("Choose at least one objective or a spelling list");
  const pupilIds = Array.isArray(b.pupilIds) && b.pupilIds.length > 0 ? b.pupilIds.filter(isUuid) : null;
  const dueDate = optionalText(b, "dueDate", 10);
  if (dueDate && !/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) throw badRequest("dueDate must be YYYY-MM-DD");
  return { classId: b.classId, title: text(b, "title", { max: 80 }), objectiveCodes, spellingListId, pupilIds, dueDate };
}

/** `from`/`to` query parameters. Defaults to the last 30 days; limited to about 13 months. */
export function parseRange(url: URL, now = new Date()): { from: string; to: string } {
  const toParam = url.searchParams.get("to");
  const fromParam = url.searchParams.get("from");
  const to = toParam ? new Date(toParam) : now;
  const from = fromParam ? new Date(fromParam) : new Date(to.getTime() - 30 * 24 * 3600 * 1000);
  if (Number.isNaN(to.getTime()) || Number.isNaN(from.getTime())) throw badRequest("from and to must be dates");
  if (from >= to) throw badRequest("from must be before to");
  if (to.getTime() - from.getTime() > 400 * 24 * 3600 * 1000) throw badRequest("Choose a range of 13 months or less");
  // A date-only `to` means "up to the end of that day".
  const end = toParam && /^\d{4}-\d{2}-\d{2}$/.test(toParam) ? new Date(to.getTime() + 24 * 3600 * 1000) : to;
  return { from: from.toISOString(), to: end.toISOString() };
}
