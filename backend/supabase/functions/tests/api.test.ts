import { assert, assertEquals, assertMatch, assertThrows } from "@std/assert";
import { routePath, Router } from "../_shared/router.ts";
import { HttpError } from "../_shared/http.ts";
import {
  MAX_ATTEMPTS_PER_BATCH,
  parseAddPupils,
  parseAssignment,
  parseAttempts,
  parseJoin,
  parseRange,
  pupilName,
} from "../_shared/validation.ts";
import { CLASS_CODE_ALPHABET, generateClassCode, generatePin, isGuessablePin, joinUrl, pickUnusedAvatar, sha256Hex } from "../_shared/codes.ts";
import { csvCell, toCsv } from "../_shared/csv.ts";
import { buildClassAnalytics, buildSatsReadiness, masteryLevel, satsBand } from "../_shared/analytics.ts";
import { handle } from "../api/index.ts";

const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, "0")}`;

Deno.test("routePath strips the function name and optional version", () => {
  assertEquals(routePath("/api/pupil/join"), "/pupil/join");
  assertEquals(routePath("/api/v1/attempts"), "/attempts");
  assertEquals(routePath("/api"), "/");
  assertEquals(routePath("/apiary"), "/apiary");
});

Deno.test("router matches parameters and reports wrong methods", async () => {
  const router = new Router().get("/classes/:id/objectives/:code", ({ params }) => Promise.resolve(new Response(JSON.stringify(params))));
  const match = router.match("GET", "/classes/abc/objectives/Y4-G-fronted-adverbials");
  assert(match && match !== "method_not_allowed");
  assertEquals(await (await match.handler({ req: new Request("http://x"), url: new URL("http://x"), params: match.params })).json(), {
    id: "abc",
    code: "Y4-G-fronted-adverbials",
  });
  assertEquals(router.match("POST", "/classes/abc/objectives/x"), "method_not_allowed");
  assertEquals(router.match("GET", "/nope"), null);
});

Deno.test("join validation", () => {
  assertEquals(parseJoin({ classCode: "abc234", avatarKey: "fox", pin: "4821" }), { classCode: "ABC234", avatarKey: "fox", pin: "4821" });
  assertThrows(() => parseJoin({ classCode: "ABC", avatarKey: "fox", pin: "4821" }), HttpError);
  assertThrows(() => parseJoin({ classCode: "ABC234", avatarKey: "fox", pin: "48a1" }), HttpError);
  assertThrows(() => parseJoin("nope"), HttpError);
});

Deno.test("attempt batches reject bad items individually and never store future times", () => {
  const now = new Date("2026-09-30T12:00:00Z");
  const good = {
    clientAttemptId: uuid(1),
    questionId: "y4-fa-01",
    correct: true,
    answerGiven: "x".repeat(500),
    timeTakenMs: 4200.6,
    hintUsed: true,
    sessionId: uuid(9),
    sessionKind: "daily",
    assignmentId: "not-a-uuid",
    answeredAt: "2026-10-05T12:00:00Z",
  };
  const { valid, rejected } = parseAttempts({
    attempts: [
      good,
      { ...good },
      { ...good, clientAttemptId: uuid(2), correct: "yes" },
      { ...good, clientAttemptId: uuid(3), answeredAt: "2020-01-01T00:00:00Z" },
      { ...good, clientAttemptId: uuid(4), sessionKind: "hacking" },
      { clientAttemptId: "junk" },
    ],
  }, now);

  assertEquals(valid.map((v) => v.clientAttemptId), [uuid(1), uuid(4)]);
  assertEquals(valid[0].answerGiven.length, 200);
  assertEquals(valid[0].timeTakenMs, 4201);
  assertEquals(valid[0].assignmentId, null);
  assertEquals(valid[0].answeredAt, now.toISOString());
  assertEquals(valid[1].sessionKind, "daily");
  assertEquals(rejected, [
    { clientAttemptId: uuid(2), reason: "invalid_correct" },
    { clientAttemptId: uuid(3), reason: "invalid_time" },
  ]);
  assertThrows(() => parseAttempts({ attempts: Array(MAX_ATTEMPTS_PER_BATCH + 1).fill(good) }), HttpError);
});

Deno.test("pupil names must be first names or nicknames", () => {
  assertEquals(pupilName("  Amara  "), "Amara");
  assertEquals(pupilName("Mary Jo"), "Mary Jo");
  assertThrows(() => pupilName("amara@school.org"), HttpError);
  assertThrows(() => pupilName("Pupil 12"), HttpError);
  assertThrows(() => pupilName(""), HttpError);
  assertThrows(() => parseAddPupils({ names: [] }), HttpError);
});

Deno.test("assignments need an objective or a spelling list", () => {
  const classId = uuid(1);
  assertThrows(() => parseAssignment({ classId, title: "Homework" }), HttpError);
  const parsed = parseAssignment({ classId, title: " Commas ", objectiveCodes: ["A", "A", 3], dueDate: "2026-10-10", pupilIds: [] });
  assertEquals(parsed, { classId, title: "Commas", objectiveCodes: ["A"], spellingListId: null, pupilIds: null, dueDate: "2026-10-10" });
  assertThrows(() => parseAssignment({ classId, title: "x", spellingListId: "y34", dueDate: "10/10/2026" }), HttpError);
});

Deno.test("date ranges default to 30 days and include the whole last day", () => {
  const now = new Date("2026-09-30T12:00:00Z");
  const defaults = parseRange(new URL("http://x/a"), now);
  assertEquals(defaults, { from: "2026-08-31T12:00:00.000Z", to: now.toISOString() });
  const days = parseRange(new URL("http://x/a?from=2026-09-01&to=2026-09-30"), now);
  assertEquals(days, { from: "2026-09-01T00:00:00.000Z", to: "2026-10-01T00:00:00.000Z" });
  assertThrows(() => parseRange(new URL("http://x/a?from=2024-01-01&to=2026-01-01"), now), HttpError);
  assertThrows(() => parseRange(new URL("http://x/a?from=2026-09-10&to=2026-09-01"), now), HttpError);
});

Deno.test("codes and tokens", async () => {
  for (let i = 0; i < 200; i++) {
    const code = generateClassCode();
    assertMatch(code, /^[A-HJ-NP-Z2-9]{6}$/);
    assert([...code].every((c) => CLASS_CODE_ALPHABET.includes(c)));
    const pin = generatePin();
    assertMatch(pin, /^\d{4}$/);
    assert(!isGuessablePin(pin));
  }
  assert(isGuessablePin("1234") && isGuessablePin("9876") && isGuessablePin("0000"));
  assert(!isGuessablePin("1357"));
  assertEquals((await sha256Hex("abc")).length, 64);
  assertEquals(pickUnusedAvatar(["fox", "cat"], new Set(["fox"])), "cat");
  assertEquals(pickUnusedAvatar(["fox"], new Set(["fox"])), null);
  assertEquals(joinUrl("ABC234", "fox", "4821"), "spagbuddy://join?class=ABC234&picture=fox&pin=4821");
});

Deno.test("CSV cells are quoted and cannot become spreadsheet formulas", () => {
  assertEquals(csvCell("plain"), "plain");
  assertEquals(csvCell('He said "hi", then left'), '"He said ""hi"", then left"');
  assertEquals(csvCell("=HYPERLINK(\"http://evil\")"), "\"'=HYPERLINK(\"\"http://evil\"\")\"");
  assertEquals(csvCell("-1"), "'-1");
  assertEquals(toCsv(["a", "b"], [[1, null]]), "a,b\r\n1,\r\n");
});

Deno.test("mastery thresholds match the app", () => {
  assertEquals(masteryLevel(0, 0, 0), "notStarted");
  assertEquals(masteryLevel(2, 2, 2), "developing");
  assertEquals(masteryLevel(3, 3, 0), "needsSupport");
  assertEquals(masteryLevel(5, 5, 4), "secure");
  assertEquals(masteryLevel(30, 10, 7), "developing");
});

Deno.test("class analytics builds a heat map with a cell per practised objective", () => {
  const pupils = [
    { id: "p1", display_name: "Zara", avatar_key: "fox" },
    { id: "p2", display_name: "Amir", avatar_key: "cat" },
    { id: "p3", display_name: "Beth", avatar_key: "owl" },
  ];
  const objectives = [
    { code: "Y4-G-a", year_group: 4, strand: "grammar", title: "A", child_title: "A" },
    { code: "Y4-P-b", year_group: 4, strand: "punctuation", title: "B", child_title: "B" },
  ];
  const rows = [
    { pupil_id: "p1", objective_code: "Y4-G-a", attempts: "6", correct: "6", recent_attempts: "6", recent_correct: "6", last_answered_at: "2026-09-02" },
    { pupil_id: "p2", objective_code: "Y4-G-a", attempts: 4, correct: 1, recent_attempts: 4, recent_correct: 1, last_answered_at: "2026-09-03" },
    { pupil_id: "gone", objective_code: "Y4-G-a", attempts: 4, correct: 1, recent_attempts: 4, recent_correct: 1, last_answered_at: "2026-09-03" },
  ] as never[];

  const result = buildClassAnalytics(rows, pupils, objectives);
  assertEquals(result.cells.length, 2);
  assertEquals(result.pupils.map((p) => p.displayName), ["Amir", "Beth", "Zara"]);
  assertEquals(result.pupils[0].needsSupport, 1);
  assertEquals(result.pupils[1].accuracy, null);
  const a = result.objectives.find((o) => o.code === "Y4-G-a")!;
  assertEquals(a.levels, { notStarted: 1, needsSupport: 1, developing: 0, secure: 1 });
  assertEquals(a.accuracy, 0.7);
  assertEquals(result.totals, { attempts: 10, accuracy: 0.7, activePupils: 2 });
});

Deno.test("SATs readiness is indicative and needs enough answers", () => {
  assertEquals(satsBand(5, 5), "notEnoughData");
  assertEquals(satsBand(10, 7), "onTrack");
  assertEquals(satsBand(10, 5), "nearly");
  assertEquals(satsBand(10, 4), "needsSupport");
  const result = buildSatsReadiness(
    [{ pupil_id: "p1", strand: "grammar", attempts: 8, correct: 7 }, { pupil_id: "p1", strand: "punctuation", attempts: 4, correct: 2 }],
    [{ id: "p1", display_name: "Zara", avatar_key: "fox" }],
  );
  assertEquals(result[0].band, "onTrack");
  assertEquals(result[0].attempts, 12);
});

Deno.test("HTTP handler: CORS, health, unknown routes and validation before any database call", async () => {
  const options = await handle(new Request("http://x/api/health", { method: "OPTIONS", headers: { Origin: "https://teach.example" } }));
  assertEquals(options.status, 204);
  assertEquals(options.headers.get("Access-Control-Allow-Origin"), "*");

  const health = await handle(new Request("http://x/api/health"));
  assertEquals(await health.json(), { ok: true });

  assertEquals((await handle(new Request("http://x/api/nope"))).status, 404);
  assertEquals((await handle(new Request("http://x/api/health", { method: "DELETE" }))).status, 405);

  const bad = await handle(new Request("http://x/api/pupil/join", { method: "POST", body: JSON.stringify({ classCode: "X" }) }));
  assertEquals(bad.status, 400);

  const unknownAvatar = await handle(new Request("http://x/api/pupil/join", {
    method: "POST",
    body: JSON.stringify({ classCode: "ABC234", avatarKey: "velociraptor", pin: "4821" }),
  }));
  assertEquals(unknownAvatar.status, 404);

  const noToken = await handle(new Request("http://x/api/classes"));
  assertEquals(noToken.status, 401);
});
