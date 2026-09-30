import { describe, expect, it } from "vitest";
import { masteryLevel, satsBand } from "@/lib/analytics.gen";
import { CLASS_CODE_ALPHABET, generateClassCode, generatePin, isGuessablePin, joinUrl } from "@/lib/codes.gen";
import { OBJECTIVES, QUESTIONS, SPELLING_LISTS } from "@/lib/content";
import { csvCell } from "@/lib/csv.gen";
import { buildDemoData, createDemoApi, slug } from "@/lib/demo-api";
import { fillDays } from "@/components/DailyChart";
import { percent, rangeFor, relativeDays } from "@/lib/format";
import { createHttpApi } from "@/lib/http-api";
import { focusObjectives, pupilsToCheckIn } from "@/lib/insights";
import { parseNames, pupilNameProblem } from "@/lib/names";
import { ApiError } from "@/lib/types";

const NOW = new Date("2026-09-30T12:00:00Z");

describe("content", () => {
  it("every question points at a known objective", () => {
    const codes = new Set(OBJECTIVES.map((o) => o.code));
    for (const q of QUESTIONS) expect(codes.has(q.objectiveCode), q.id).toBe(true);
  });

  it("every spelling list includes its words", () => {
    for (const list of SPELLING_LISTS) expect(list.words.length).toBe(list.wordCount);
  });

  it("slugs match the iOS SpellingQuestionFactory", () => {
    expect(slug("Wednesday")).toBe("wednesday");
    expect(slug("it's")).toBe("it-s");
    expect(slug("  mum's  bag ")).toBe("mum-s-bag");
  });
});

describe("mastery rules shared with the app", () => {
  it("needs five answers and 80% to be secure", () => {
    expect(masteryLevel(0, 0, 0)).toBe("notStarted");
    expect(masteryLevel(4, 4, 4)).toBe("developing");
    expect(masteryLevel(5, 5, 4)).toBe("secure");
    expect(masteryLevel(3, 3, 1)).toBe("needsSupport");
    expect(masteryLevel(2, 2, 0)).toBe("developing");
  });

  it("gives an indicative SATs band only after ten answers", () => {
    expect(satsBand(9, 9)).toBe("notEnoughData");
    expect(satsBand(10, 7)).toBe("onTrack");
    expect(satsBand(10, 5)).toBe("nearly");
    expect(satsBand(10, 4)).toBe("needsSupport");
  });
});

describe("codes", () => {
  it("makes class codes without confusable characters", () => {
    for (let i = 0; i < 200; i++) expect(generateClassCode()).toMatch(/^[A-HJ-NP-Z2-9]{6}$/);
    expect(CLASS_CODE_ALPHABET).not.toMatch(/[IO01]/);
  });

  it("never makes guessable PINs", () => {
    for (let i = 0; i < 500; i++) {
      const pin = generatePin();
      expect(pin).toMatch(/^\d{4}$/);
      expect(isGuessablePin(pin)).toBe(false);
    }
    expect(isGuessablePin("1111")).toBe(true);
    expect(isGuessablePin("4321")).toBe(true);
  });

  it("builds the deep link the iPad app understands", () => {
    expect(joinUrl("ABC234", "fox", "0482")).toBe("spagbuddy://join?class=ABC234&picture=fox&pin=0482");
  });
});

describe("CSV export", () => {
  it("stops typed answers running as spreadsheet formulas", () => {
    expect(csvCell("=HYPERLINK(\"x\")")).toBe(`"'=HYPERLINK(""x"")"`);
    expect(csvCell("-1")).toBe("'-1");
    expect(csvCell("because, then")).toBe('"because, then"');
  });
});

describe("names", () => {
  it("splits pasted lists and drops blanks and repeats", () => {
    expect(parseNames("Amara\n  Ben  K \n\nChloe, amara")).toEqual(["Amara", "Ben K", "Chloe"]);
  });

  it("flags surnames-with-numbers and emails", () => {
    expect(pupilNameProblem("Sam")).toBeNull();
    expect(pupilNameProblem("sam@school.uk")).not.toBeNull();
    expect(pupilNameProblem("Sam 2")).not.toBeNull();
    expect(pupilNameProblem("A".repeat(31))).not.toBeNull();
  });
});

describe("formatting", () => {
  it("formats percentages and gaps", () => {
    expect(percent(0.834)).toBe("83%");
    expect(percent(null)).toBe("–");
  });

  it("starts the school year on 1 September", () => {
    expect(rangeFor("year", NOW).from).toBe("2026-09-01T00:00:00.000Z");
    expect(rangeFor("year", new Date("2027-03-01T00:00:00Z")).from).toBe("2026-09-01T00:00:00.000Z");
  });

  it("describes last activity", () => {
    expect(relativeDays(null, NOW)).toBe("Never");
    expect(relativeDays("2026-09-30T08:00:00Z", NOW)).toBe("Today");
    expect(relativeDays("2026-09-27T08:00:00Z", NOW)).toBe("3 days ago");
  });

  it("fills empty days on the practice chart", () => {
    const days = fillDays([{ day: "2026-09-29", attempts: 5, correct: 3 }], rangeFor("7d", NOW));
    expect(days).toHaveLength(7);
    expect(days.find((d) => d.day === "2026-09-29")?.attempts).toBe(5);
    expect(days.filter((d) => d.attempts === 0)).toHaveLength(6);
  });
});

describe("insights", () => {
  const pupil = (id: string, lastActiveAt: string | null, needsSupport = 0) => ({
    id,
    displayName: id,
    avatarKey: "fox",
    attempts: 10,
    accuracy: 0.5,
    lastActiveAt,
    needsSupport,
  });

  it("lists pupils who have not practised or are stuck", () => {
    const result = pupilsToCheckIn(
      { pupils: [pupil("Ada", "2026-09-29T10:00:00Z"), pupil("Ben", null), pupil("Cal", "2026-09-01T10:00:00Z"), pupil("Dee", "2026-09-29T10:00:00Z", 3)] },
      NOW,
    );
    expect(result.map((r) => r.pupil.id)).toEqual(["Ben", "Dee", "Cal"]);
  });

  it("puts the hardest skills first", () => {
    const levels = (needsSupport: number) => ({ notStarted: 0, needsSupport, developing: 1, secure: 1 });
    const objective = (code: string, needsSupport: number, accuracy: number) => ({ code, yearGroup: 4, strand: "grammar", title: code, attempts: 20, accuracy, levels: levels(needsSupport) });
    const result = focusObjectives({ objectives: [objective("a", 0, 0.9), objective("b", 3, 0.4), objective("c", 0, 0.5), objective("d", 5, 0.3)] });
    expect(result.map((o) => o.code)).toEqual(["d", "b", "c"]);
  });
});

describe("demo API", () => {
  it("is deterministic and realistic", () => {
    const a = buildDemoData(NOW);
    const b = buildDemoData(NOW);
    expect(a.attempts.length).toBe(b.attempts.length);
    expect(a.pupils.map((p) => p.displayName)).toEqual(b.pupils.map((p) => p.displayName));
    expect(a.attempts.length).toBeGreaterThan(1000);
    expect(a.attempts.every((t) => t.answeredAt <= NOW.toISOString())).toBe(true);
  });

  it("answers analytics requests like the real API", async () => {
    const demo = createDemoApi(buildDemoData(NOW), 0);
    const [kestrels] = (await demo.listClasses()).filter((c) => c.yearGroup === 4);
    const range = rangeFor("30d", NOW);
    const analytics = await demo.classAnalytics(kestrels.id, range);
    expect(analytics.pupils).toHaveLength(26);
    expect(analytics.totals.attempts).toBe(analytics.cells.reduce((s, c) => s + c.attempts, 0));
    for (const o of analytics.objectives) {
      expect(Object.values(o.levels).reduce((s, n) => s + n, 0)).toBe(26);
    }

    const tried = analytics.objectives.find((o) => o.attempts > 0)!;
    const detail = await demo.objectiveDetail(kestrels.id, tried.code, range);
    expect(detail.questions.reduce((s, q) => s + q.attempts, 0)).toBe(tried.attempts);

    const progress = await demo.pupilProgress(analytics.pupils[0].id, range);
    expect(progress.daily.reduce((s, d) => s + d.attempts, 0)).toBe(analytics.pupils[0].attempts);
  });

  it("adds pupils, issues login cards and deletes data", async () => {
    const demo = createDemoApi(buildDemoData(NOW), 0);
    const created = await demo.createClass({ name: "Robins", yearGroup: 3 });
    const cards = await demo.addPupils(created.id, ["Ada", "Ben"]);
    expect(cards.cards).toHaveLength(2);
    expect(new Set(cards.cards.map((c) => c.avatarKey)).size).toBe(2);
    expect(cards.cards[0].joinUrl).toContain(`class=${created.classCode}`);
    await expect(demo.addPupils(created.id, ["Sam 2"])).rejects.toBeInstanceOf(ApiError);

    await demo.deletePupil(cards.cards[0].pupilId);
    expect((await demo.getClass(created.id)).pupils).toHaveLength(1);
    await demo.deleteClass(created.id);
    await expect(demo.getClass(created.id)).rejects.toMatchObject({ status: 404 });
  });

  it("exports CSV with a header row", async () => {
    const demo = createDemoApi(buildDemoData(NOW), 0);
    const [first] = await demo.listClasses();
    const { blob, filename } = await demo.exportCsv(first.id, rangeFor("7d", NOW));
    const text = await blob.text();
    expect(filename).toMatch(/\.csv$/);
    expect(text.split("\r\n")[0]).toBe("Pupil,Answered at,Objective,Strand,Question,Correct,Answer given,Seconds,Hint used,Session type");
  });
});

describe("HTTP API", () => {
  it("sends the teacher's token and turns errors into ApiError", async () => {
    const calls: { url: string; init: RequestInit }[] = [];
    const fetcher = (async (url: string, init: RequestInit) => {
      calls.push({ url, init });
      if (url.endsWith("/classes")) return new Response(JSON.stringify({ classes: [{ id: "c1" }] }), { status: 200 });
      return new Response(JSON.stringify({ error: "forbidden", message: "Not your class" }), { status: 403 });
    }) as unknown as typeof fetch;
    const http = createHttpApi("https://x.supabase.co/functions/v1/api", async () => "token-1", fetcher);

    expect(await http.listClasses()).toEqual([{ id: "c1" }]);
    expect((calls[0].init.headers as Record<string, string>).Authorization).toBe("Bearer token-1");
    await expect(http.getClass("c2")).rejects.toMatchObject({ status: 403, code: "forbidden", message: "Not your class" });
  });

  it("treats a missing profile as a new teacher", async () => {
    const fetcher = (async () => new Response(JSON.stringify({ error: "profile_required" }), { status: 404 })) as unknown as typeof fetch;
    const http = createHttpApi("https://x", async () => "t", fetcher);
    expect(await http.me()).toBeNull();
  });

  it("refuses to call the API without a session", async () => {
    const http = createHttpApi("https://x", async () => null, (() => {
      throw new Error("should not fetch");
    }) as unknown as typeof fetch);
    await expect(http.listClasses()).rejects.toMatchObject({ status: 401 });
  });
});
