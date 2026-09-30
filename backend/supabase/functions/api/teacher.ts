import type { SupabaseClient } from "@supabase/supabase-js";
import type { Router } from "../_shared/router.ts";
import { badRequest, HttpError, json, notFound, readJson } from "../_shared/http.ts";
import {
  authenticateTeacher,
  check,
  CLASS_COLUMNS,
  type ClassRow,
  requireClass,
  requireTeacher,
  serviceClient,
  userClient,
} from "../_shared/db.ts";
import {
  isUuid,
  parseAddPupils,
  parseAssignment,
  parseCreateClass,
  parseRange,
  parseTeacherProfile,
  parseUpdateClass,
  pupilName,
} from "../_shared/validation.ts";
import { generateClassCode, generatePin, joinUrl, pickUnusedAvatar } from "../_shared/codes.ts";
import {
  buildClassAnalytics,
  buildSatsReadiness,
  masteryLevel,
  type ObjectiveRow,
  type ObjectiveStatRow,
  type PupilRow,
  type SatsRow,
} from "../_shared/analytics.ts";
import { toCsv } from "../_shared/csv.ts";
import { AVATAR_KEYS } from "../_shared/content.gen.ts";

const PUPIL_COLUMNS = "id, class_id, display_name, avatar_key, created_at, locked_until";

async function audit(teacherId: string, action: string, targetType: string, targetId: string) {
  await serviceClient().from("audit_log").insert({ teacher_id: teacherId, action, target_type: targetType, target_id: targetId });
}

function classJson(c: ClassRow, pupilCount?: number) {
  return {
    id: c.id,
    name: c.name,
    yearGroup: c.year_group,
    classCode: c.class_code,
    archived: c.archived_at !== null,
    createdAt: c.created_at,
    ...(pupilCount === undefined ? {} : { pupilCount }),
  };
}

async function classPupils(db: SupabaseClient, classId: string): Promise<PupilRow[]> {
  return check(await db.from("pupils").select(PUPIL_COLUMNS).eq("class_id", classId).order("display_name")) as PupilRow[];
}

/** Objectives for the class's year and the year below, plus any others the class has practised. */
async function classObjectives(db: SupabaseClient, yearGroup: number, extraCodes: string[]): Promise<ObjectiveRow[]> {
  const years = [Math.max(1, yearGroup - 1), yearGroup];
  const byYear = check(await db.from("objectives").select("code, year_group, strand, title, child_title").in("year_group", years)) as ObjectiveRow[];
  const known = new Set(byYear.map((o) => o.code));
  const missing = [...new Set(extraCodes)].filter((c) => !known.has(c));
  const extra = missing.length
    ? (check(await db.from("objectives").select("code, year_group, strand, title, child_title").in("code", missing)) as ObjectiveRow[])
    : [];
  return [...byYear, ...extra];
}

/** Creates a fresh PIN for each pupil and returns the details printed on their login cards. */
async function issueLoginCards(klass: ClassRow, pupils: PupilRow[]) {
  const service = serviceClient();
  const cards = [];
  for (const pupil of pupils) {
    const pin = generatePin();
    const hash = check(await service.rpc("hash_pin", { p_pin: pin })) as string;
    check(await service.from("pupils").update({ pin_hash: hash, failed_logins: 0, locked_until: null }).eq("id", pupil.id));
    cards.push({
      pupilId: pupil.id,
      displayName: pupil.display_name,
      avatarKey: pupil.avatar_key,
      pin,
      joinUrl: joinUrl(klass.class_code, pupil.avatar_key, pin),
    });
  }
  return { classCode: klass.class_code, className: klass.name, cards };
}

export function teacherRoutes(router: Router) {
  // ---- Profile -------------------------------------------------------------

  router.get("/teacher/me", async ({ req }) => {
    const db = userClient(req);
    const { teacher } = await authenticateTeacher(req, db);
    if (!teacher) throw new HttpError(404, "profile_required", "No teacher profile yet");
    const school = teacher.schoolId
      ? await db.from("schools").select("id, name, urn").eq("id", teacher.schoolId).maybeSingle()
      : { data: null };
    return json({ teacher, school: school.data });
  });

  router.post("/teacher/profile", async ({ req }) => {
    const db = userClient(req);
    const { userId, teacher } = await authenticateTeacher(req, db);
    const input = parseTeacherProfile(await readJson(req));
    const service = serviceClient();

    let schoolId = teacher?.schoolId ?? null;
    if (!schoolId) {
      const school = check(await service.from("schools").insert({ name: input.schoolName, urn: input.urn }).select("id").single()) as { id: string };
      schoolId = school.id;
    } else {
      check(await service.from("schools").update({ name: input.schoolName, urn: input.urn }).eq("id", schoolId));
    }
    check(await service.from("teachers").upsert({ id: userId, school_id: schoolId, display_name: input.displayName }));
    return json({ teacher: { id: userId, schoolId, displayName: input.displayName } });
  });

  // ---- Classes -------------------------------------------------------------

  router.get("/classes", async ({ req }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const classes = check(await db.from("classes").select(CLASS_COLUMNS).order("created_at", { ascending: false })) as ClassRow[];
    const pupils = classes.length
      ? (check(await db.from("pupils").select("class_id").in("class_id", classes.map((c) => c.id))) as { class_id: string }[])
      : [];
    const counts = new Map<string, number>();
    for (const p of pupils) counts.set(p.class_id, (counts.get(p.class_id) ?? 0) + 1);
    return json({ classes: classes.map((c) => classJson(c, counts.get(c.id) ?? 0)) });
  });

  router.post("/classes", async ({ req }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    const input = parseCreateClass(await readJson(req));
    const service = serviceClient();

    let created: ClassRow | null = null;
    for (let attempt = 0; attempt < 5 && !created; attempt++) {
      const result = await service
        .from("classes")
        .insert({ name: input.name, year_group: input.yearGroup, class_code: generateClassCode(), school_id: teacher.schoolId })
        .select(CLASS_COLUMNS)
        .single();
      if (!result.error) created = result.data as ClassRow;
      else if (result.error.code !== "23505") throw new HttpError(500, "database_error", result.error.message);
    }
    if (!created) throw new HttpError(500, "class_code_exhausted", "Could not create a class code. Try again.");

    check(await service.from("class_teachers").insert({ class_id: created.id, teacher_id: teacher.id, role: "owner" }));
    return json({ class: classJson(created, 0) }, 201);
  });

  router.get("/classes/:id", async ({ req, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const pupils = await classPupils(db, klass.id);
    return json({
      class: classJson(klass, pupils.length),
      pupils: pupils.map((p) => ({
        id: p.id,
        displayName: p.display_name,
        avatarKey: p.avatar_key,
        // deno-lint-ignore no-explicit-any
        locked: !!(p as any).locked_until && new Date((p as any).locked_until) > new Date(),
      })),
    });
  });

  router.patch("/classes/:id", async ({ req, params }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    await requireClass(db, params.id);
    const input = parseUpdateClass(await readJson(req));
    const update: Record<string, unknown> = {};
    if (input.name !== undefined) update.name = input.name;
    if (input.yearGroup !== undefined) update.year_group = input.yearGroup;
    if (input.archived !== undefined) update.archived_at = input.archived ? new Date().toISOString() : null;
    const updated = check(await db.from("classes").update(update).eq("id", params.id).select(CLASS_COLUMNS).single()) as ClassRow;
    if (input.archived) await audit(teacher.id, "archive_class", "class", params.id);
    return json({ class: classJson(updated) });
  });

  /** Permanently deletes a class with all of its pupils and results (for example, for an erasure request). */
  router.delete("/classes/:id", async ({ req, params }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    await requireClass(db, params.id);
    check(await serviceClient().from("classes").delete().eq("id", params.id));
    await audit(teacher.id, "delete_class", "class", params.id);
    return json({ deleted: true });
  });

  // ---- Pupils --------------------------------------------------------------

  router.post("/classes/:id/pupils", async ({ req, params }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const names = parseAddPupils(await readJson(req));
    const existing = await classPupils(db, klass.id);
    if (existing.length + names.length > AVATAR_KEYS.length) {
      throw badRequest(`A class can have up to ${AVATAR_KEYS.length} pupils`);
    }

    const service = serviceClient();
    const used = new Set(existing.map((p) => p.avatar_key));
    const created: PupilRow[] = [];
    for (const name of names) {
      const avatar = pickUnusedAvatar(AVATAR_KEYS, used);
      if (!avatar) break;
      used.add(avatar);
      const placeholder = check(await service.rpc("hash_pin", { p_pin: crypto.randomUUID() })) as string;
      const row = check(
        await service.from("pupils").insert({ class_id: klass.id, display_name: name, avatar_key: avatar, pin_hash: placeholder }).select(PUPIL_COLUMNS).single(),
      ) as PupilRow;
      created.push(row);
    }
    await audit(teacher.id, "add_pupils", "class", klass.id);
    return json(await issueLoginCards(klass, created), 201);
  });

  /** Prints new login cards. Resets PINs, but iPads that have already joined keep working. */
  router.post("/classes/:id/login-cards", async ({ req, params }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const body = (await readJson(req)) as { pupilIds?: unknown };
    let pupils = await classPupils(db, klass.id);
    if (Array.isArray(body.pupilIds) && body.pupilIds.length) {
      const wanted = new Set(body.pupilIds.filter(isUuid));
      pupils = pupils.filter((p) => wanted.has(p.id));
    }
    await audit(teacher.id, "reset_pins", "class", klass.id);
    return json(await issueLoginCards(klass, pupils));
  });

  router.patch("/pupils/:id", async ({ req, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const body = (await readJson(req)) as { displayName?: unknown };
    const updated = check(
      await db.from("pupils").update({ display_name: pupilName(body.displayName) }).eq("id", params.id).select(PUPIL_COLUMNS).maybeSingle(),
    ) as PupilRow | null;
    if (!updated) throw notFound("Pupil not found");
    return json({ pupil: { id: updated.id, displayName: updated.display_name, avatarKey: updated.avatar_key } });
  });

  /** Deletes the pupil, their results and their device links. */
  router.delete("/pupils/:id", async ({ req, params }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    const pupil = check(await db.from("pupils").select("id").eq("id", params.id).maybeSingle());
    if (!pupil) throw notFound("Pupil not found");
    check(await serviceClient().from("pupils").delete().eq("id", params.id));
    await audit(teacher.id, "delete_pupil", "pupil", params.id);
    return json({ deleted: true });
  });

  // ---- Assignments ---------------------------------------------------------

  router.get("/classes/:id/assignments", async ({ req, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const rows = check(
      await db
        .from("assignments")
        .select("id, title, objective_codes, spelling_list_id, pupil_ids, due_date, created_at")
        .eq("class_id", klass.id)
        .is("archived_at", null)
        .order("created_at", { ascending: false }),
    ) as { id: string; title: string; objective_codes: string[]; spelling_list_id: string | null; pupil_ids: string[] | null; due_date: string | null; created_at: string }[];
    const progress = check(await db.rpc("class_assignment_progress", { p_class_id: klass.id })) as {
      assignment_id: string; pupils_started: number; attempts: number; correct: number;
    }[];
    const byId = new Map(progress.map((p) => [p.assignment_id, p]));
    const pupilCount = (await classPupils(db, klass.id)).length;

    return json({
      assignments: rows.map((a) => {
        const p = byId.get(a.id);
        const attempts = Number(p?.attempts ?? 0);
        return {
          id: a.id,
          title: a.title,
          objectiveCodes: a.objective_codes,
          spellingListId: a.spelling_list_id,
          pupilIds: a.pupil_ids,
          dueDate: a.due_date,
          createdAt: a.created_at,
          assignedPupils: a.pupil_ids?.length ?? pupilCount,
          pupilsStarted: Number(p?.pupils_started ?? 0),
          attempts,
          accuracy: attempts ? Number(p?.correct ?? 0) / attempts : null,
        };
      }),
    });
  });

  router.post("/assignments", async ({ req }) => {
    const db = userClient(req);
    const teacher = await requireTeacher(req, db);
    const input = parseAssignment(await readJson(req));
    await requireClass(db, input.classId);

    if (input.objectiveCodes.length) {
      const found = check(await db.from("objectives").select("code").in("code", input.objectiveCodes)) as { code: string }[];
      if (found.length !== input.objectiveCodes.length) throw badRequest("Unknown objective");
    }
    if (input.pupilIds) {
      const pupils = check(await db.from("pupils").select("id").eq("class_id", input.classId).in("id", input.pupilIds)) as { id: string }[];
      if (pupils.length !== input.pupilIds.length) throw badRequest("Some pupils are not in this class");
    }

    const created = check(
      await db
        .from("assignments")
        .insert({
          class_id: input.classId,
          created_by: teacher.id,
          title: input.title,
          objective_codes: input.objectiveCodes,
          spelling_list_id: input.spellingListId,
          pupil_ids: input.pupilIds,
          due_date: input.dueDate,
        })
        .select("id")
        .single(),
    ) as { id: string };
    return json({ assignment: { id: created.id } }, 201);
  });

  router.delete("/assignments/:id", async ({ req, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const updated = check(
      await db.from("assignments").update({ archived_at: new Date().toISOString() }).eq("id", params.id).select("id").maybeSingle(),
    );
    if (!updated) throw notFound("Assignment not found");
    return json({ archived: true });
  });

  // ---- Analytics -----------------------------------------------------------

  router.get("/classes/:id/analytics", async ({ req, url, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const range = parseRange(url);
    const [pupils, stats] = await Promise.all([
      classPupils(db, klass.id),
      db.rpc("class_objective_stats", { p_class_id: klass.id, p_from: range.from, p_to: range.to }).then(check) as Promise<ObjectiveStatRow[]>,
    ]);
    const objectives = await classObjectives(db, klass.year_group, stats.map((s) => s.objective_code));
    return json({ class: classJson(klass, pupils.length), range, ...buildClassAnalytics(stats, pupils, objectives) });
  });

  router.get("/classes/:id/objectives/:code", async ({ req, url, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const range = parseRange(url);
    const objective = check(await db.from("objectives").select("code, year_group, strand, title, child_title, rule").eq("code", params.code).maybeSingle());
    if (!objective) throw notFound("Objective not found");

    const args = { p_class_id: klass.id, p_objective_code: params.code, p_from: range.from, p_to: range.to };
    const [questions, misconceptions, stats, pupils] = await Promise.all([
      db.rpc("class_question_stats", args).then(check) as Promise<{ question_id: string; prompt: string; attempts: number; correct: number; pupils: number }[]>,
      db.rpc("class_misconceptions", args).then(check) as Promise<{ question_id: string; prompt: string; answer_given: string; times: number; pupils: number }[]>,
      db.rpc("class_objective_stats", { p_class_id: klass.id, p_from: range.from, p_to: range.to }).then(check) as Promise<ObjectiveStatRow[]>,
      classPupils(db, klass.id),
    ]);
    const mine = new Map(stats.filter((s) => s.objective_code === params.code).map((s) => [s.pupil_id, s]));

    return json({
      class: classJson(klass),
      range,
      objective,
      questions: questions.map((q) => ({
        questionId: q.question_id,
        prompt: q.prompt,
        attempts: Number(q.attempts),
        accuracy: Number(q.attempts) ? Number(q.correct) / Number(q.attempts) : null,
        pupils: Number(q.pupils),
      })),
      misconceptions: misconceptions.map((m) => ({
        questionId: m.question_id,
        prompt: m.prompt,
        answerGiven: m.answer_given,
        times: Number(m.times),
        pupils: Number(m.pupils),
      })),
      pupils: pupils.map((p) => {
        const s = mine.get(p.id);
        return {
          id: p.id,
          displayName: p.display_name,
          avatarKey: p.avatar_key,
          attempts: Number(s?.attempts ?? 0),
          accuracy: s && Number(s.attempts) ? Number(s.correct) / Number(s.attempts) : null,
          level: masteryLevel(Number(s?.attempts ?? 0), Number(s?.recent_attempts ?? 0), Number(s?.recent_correct ?? 0)),
        };
      }),
    });
  });

  router.get("/pupils/:id/progress", async ({ req, url, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const pupil = check(await db.from("pupils").select(PUPIL_COLUMNS).eq("id", params.id).maybeSingle()) as (PupilRow & { class_id: string }) | null;
    if (!pupil) throw notFound("Pupil not found");
    const klass = await requireClass(db, pupil.class_id);
    const range = parseRange(url);

    const [daily, sessions, spelling, stats] = await Promise.all([
      db.rpc("pupil_daily_stats", { p_pupil_id: pupil.id, p_from: range.from, p_to: range.to }).then(check) as Promise<{ day: string; attempts: number; correct: number }[]>,
      db.rpc("pupil_sessions", { p_pupil_id: pupil.id, p_limit: 20 }).then(check) as Promise<{ session_id: string; session_kind: string; started_at: string; attempts: number; correct: number; strands: string[] }[]>,
      db.rpc("pupil_spelling_mastery", { p_pupil_id: pupil.id }).then(check) as Promise<{ spelling_list_id: string; words_attempted: number; words_mastered: number }[]>,
      db.rpc("class_objective_stats", { p_class_id: klass.id, p_from: range.from, p_to: range.to }).then(check) as Promise<ObjectiveStatRow[]>,
    ]);
    const mine = stats.filter((s) => s.pupil_id === pupil.id);
    const objectives = await classObjectives(db, klass.year_group, mine.map((s) => s.objective_code));
    const analytics = buildClassAnalytics(mine, [pupil], objectives);

    return json({
      class: classJson(klass),
      pupil: { id: pupil.id, displayName: pupil.display_name, avatarKey: pupil.avatar_key },
      range,
      summary: analytics.pupils[0],
      objectives: analytics.objectives.map((o) => {
        const cell = analytics.cells.find((c) => c.objectiveCode === o.code);
        return { code: o.code, title: o.title, strand: o.strand, yearGroup: o.yearGroup, attempts: cell?.attempts ?? 0, recentAccuracy: cell?.recentAccuracy ?? null, level: cell?.level ?? "notStarted" };
      }),
      daily: daily.map((d) => ({ day: d.day, attempts: Number(d.attempts), correct: Number(d.correct) })),
      sessions: sessions.map((s) => ({
        sessionId: s.session_id,
        kind: s.session_kind,
        startedAt: s.started_at,
        attempts: Number(s.attempts),
        correct: Number(s.correct),
        strands: s.strands,
      })),
      spelling: spelling.map((s) => ({ spellingListId: s.spelling_list_id, wordsAttempted: Number(s.words_attempted), wordsMastered: Number(s.words_mastered) })),
    });
  });

  router.get("/classes/:id/sats", async ({ req, url, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const range = parseRange(url);
    const [rows, pupils] = await Promise.all([
      db.rpc("class_sats_stats", { p_class_id: klass.id, p_from: range.from, p_to: range.to }).then(check) as Promise<SatsRow[]>,
      classPupils(db, klass.id),
    ]);
    return json({ class: classJson(klass, pupils.length), range, pupils: buildSatsReadiness(rows, pupils) });
  });

  router.get("/classes/:id/export.csv", async ({ req, url, params }) => {
    const db = userClient(req);
    await requireTeacher(req, db);
    const klass = await requireClass(db, params.id);
    const range = parseRange(url);
    const pupils = new Map((await classPupils(db, klass.id)).map((p) => [p.id, p.display_name]));

    const rows: unknown[][] = [];
    const pageSize = 1000;
    for (let from = 0; ; from += pageSize) {
      const page = check(
        await db
          .from("attempts")
          .select("pupil_id, answered_at, objective_code, strand, question_id, correct, answer_given, time_taken_ms, hint_used, session_kind")
          .eq("class_id", klass.id)
          .gte("answered_at", range.from)
          .lt("answered_at", range.to)
          .order("answered_at")
          .range(from, from + pageSize - 1),
      ) as Record<string, unknown>[];
      for (const a of page) {
        rows.push([
          pupils.get(a.pupil_id as string) ?? "(deleted)",
          a.answered_at,
          a.objective_code,
          a.strand,
          a.question_id,
          a.correct ? "yes" : "no",
          a.answer_given,
          Math.round(Number(a.time_taken_ms) / 1000),
          a.hint_used ? "yes" : "no",
          a.session_kind,
        ]);
      }
      if (page.length < pageSize || rows.length >= 100_000) break;
    }

    const csv = toCsv(
      ["Pupil", "Answered at", "Objective", "Strand", "Question", "Correct", "Answer given", "Seconds", "Hint used", "Session type"],
      rows,
    );
    const filename = `${klass.name.replace(/[^A-Za-z0-9]+/g, "-")}-${range.from.slice(0, 10)}-to-${range.to.slice(0, 10)}.csv`;
    return new Response(csv, {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${filename}"`,
        "Cache-Control": "no-store",
      },
    });
  });
}
