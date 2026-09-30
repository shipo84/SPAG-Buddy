import type { Router } from "../_shared/router.ts";
import { HttpError, json, notFound, readJson } from "../_shared/http.ts";
import { authenticatePupil, check, serviceClient } from "../_shared/db.ts";
import { parseAttempts, parseJoin, type Rejected } from "../_shared/validation.ts";
import { generateDeviceToken, sha256Hex } from "../_shared/codes.ts";
import { AVATAR_KEYS, CONTENT_FILES, CONTENT_VERSION } from "../_shared/content.gen.ts";

export function pupilRoutes(router: Router) {
  router.post("/pupil/join", async ({ req }) => {
    const input = parseJoin(await readJson(req, 2_000));
    if (!AVATAR_KEYS.includes(input.avatarKey)) throw notFound("Those details did not match");

    const db = serviceClient();
    const token = generateDeviceToken();
    const rows = check(
      await db.rpc("pupil_join", {
        p_class_code: input.classCode,
        p_avatar_key: input.avatarKey,
        p_pin: input.pin,
        p_token_hash: await sha256Hex(token),
      }),
    ) as { status: string; pupil_id: string; display_name: string; avatar_key: string; year_group: number; class_name: string; class_code: string }[];

    const row = rows[0];
    if (!row || row.status === "not_found") throw notFound("Class not found");
    if (row.status === "locked") throw new HttpError(429, "too_many_attempts", "Too many tries. Ask your teacher for help.");
    if (row.status !== "ok") throw new HttpError(401, "wrong_details", "Those details did not match");

    return json({
      pupilId: row.pupil_id,
      displayName: row.display_name,
      avatarKey: row.avatar_key,
      yearGroup: row.year_group,
      className: row.class_name,
      classCode: row.class_code,
      deviceToken: token,
    });
  });

  router.get("/content/manifest", () => {
    const base = Deno.env.get("CONTENT_BASE_URL")?.replace(/\/$/, "") ?? null;
    return Promise.resolve(json({
      contentVersion: CONTENT_VERSION,
      baseUrl: base,
      files: base ? CONTENT_FILES.map((name) => ({ name, url: `${base}/${CONTENT_VERSION}/${name}` })) : [],
    }));
  });

  router.get("/assignments", async ({ req }) => {
    const db = serviceClient();
    const pupil = await authenticatePupil(req, db);
    const rows = check(
      await db
        .from("assignments")
        .select("id, title, objective_codes, spelling_list_id, due_date, pupil_ids")
        .eq("class_id", pupil.classId)
        .is("archived_at", null)
        .or(`pupil_ids.is.null,pupil_ids.cs.{${pupil.pupilId}}`)
        .order("created_at", { ascending: false })
        .limit(20),
    ) as { id: string; title: string; objective_codes: string[]; spelling_list_id: string | null; due_date: string | null }[];

    return json({
      assignments: rows.map((a) => ({
        id: a.id,
        title: a.title,
        objectiveCodes: a.objective_codes,
        spellingListId: a.spelling_list_id,
        dueDate: a.due_date,
      })),
    });
  });

  router.post("/attempts", async ({ req }) => {
    const db = serviceClient();
    const pupil = await authenticatePupil(req, db);
    const { valid, rejected } = parseAttempts(await readJson(req));
    const accepted: string[] = [];
    const permanentlyRejected: Rejected[] = [...rejected];

    if (valid.length > 0) {
      // The server decides the objective and strand from its own copy of the question.
      const questionIds = [...new Set(valid.map((a) => a.questionId))];
      const questions = check(
        await db.from("questions").select("id, objective_code, objectives!inner(strand)").in("id", questionIds),
      ) as unknown as { id: string; objective_code: string; objectives: { strand: string } }[];
      const byId = new Map(questions.map((q) => [q.id, q]));

      const assignmentIds = [...new Set(valid.map((a) => a.assignmentId).filter((id): id is string => !!id))];
      const assignments = assignmentIds.length
        ? (check(await db.from("assignments").select("id").eq("class_id", pupil.classId).in("id", assignmentIds)) as { id: string }[])
        : [];
      const validAssignments = new Set(assignments.map((a) => a.id));

      const rows = [];
      for (const attempt of valid) {
        const question = byId.get(attempt.questionId);
        if (!question) {
          permanentlyRejected.push({ clientAttemptId: attempt.clientAttemptId, reason: "unknown_question" });
          continue;
        }
        rows.push({
          client_attempt_id: attempt.clientAttemptId,
          pupil_id: pupil.pupilId,
          class_id: pupil.classId,
          question_id: question.id,
          objective_code: question.objective_code,
          strand: question.objectives.strand,
          correct: attempt.correct,
          answer_given: attempt.answerGiven,
          time_taken_ms: attempt.timeTakenMs,
          hint_used: attempt.hintUsed,
          session_id: attempt.sessionId,
          session_kind: attempt.sessionKind,
          assignment_id: attempt.assignmentId && validAssignments.has(attempt.assignmentId) ? attempt.assignmentId : null,
          answered_at: attempt.answeredAt,
        });
      }

      if (rows.length > 0) {
        // Retried batches are ignored rather than counted twice.
        check(await db.from("attempts").upsert(rows, { onConflict: "client_attempt_id", ignoreDuplicates: true }));
        accepted.push(...rows.map((r) => r.client_attempt_id));
      }
    }

    return json({ accepted, rejected: permanentlyRejected });
  });
}
