import type { DateRange, Level, SatsBand } from "./types";

export const LEVELS: Record<Level, { label: string; short: string; className: string }> = {
  secure: { label: "Secure", short: "S", className: "level-secure" },
  developing: { label: "Developing", short: "D", className: "level-developing" },
  needsSupport: { label: "Needs support", short: "!", className: "level-support" },
  notStarted: { label: "Not started", short: "–", className: "level-none" },
};

export const LEVEL_ORDER: Level[] = ["needsSupport", "developing", "secure", "notStarted"];

export const SATS_BANDS: Record<SatsBand, { label: string; className: string }> = {
  onTrack: { label: "On track", className: "level-secure" },
  nearly: { label: "Nearly there", className: "level-developing" },
  needsSupport: { label: "Needs support", className: "level-support" },
  notEnoughData: { label: "Not enough answers yet", className: "level-none" },
};

export function percent(value: number | null | undefined): string {
  return value === null || value === undefined ? "–" : `${Math.round(value * 100)}%`;
}

const dateFormat = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric", timeZone: "Europe/London" });
const dateTimeFormat = new Intl.DateTimeFormat("en-GB", {
  day: "numeric",
  month: "short",
  hour: "2-digit",
  minute: "2-digit",
  timeZone: "Europe/London",
});

export const formatDate = (iso: string | null | undefined) => (iso ? dateFormat.format(new Date(iso)) : "–");
export const formatDateTime = (iso: string | null | undefined) => (iso ? dateTimeFormat.format(new Date(iso)) : "–");

/** "3 days ago" style labels for last-active columns. */
export function relativeDays(iso: string | null | undefined, now = new Date()): string {
  if (!iso) return "Never";
  const days = Math.floor((now.getTime() - new Date(iso).getTime()) / 86_400_000);
  if (days <= 0) return "Today";
  if (days === 1) return "Yesterday";
  if (days < 14) return `${days} days ago`;
  return formatDate(iso);
}

export type RangePreset = "7d" | "30d" | "90d" | "year";

export const RANGE_PRESETS: { value: RangePreset; label: string }[] = [
  { value: "7d", label: "Last 7 days" },
  { value: "30d", label: "Last 30 days" },
  { value: "90d", label: "Last 90 days" },
  { value: "year", label: "This school year" },
];

/** The English school year starts on 1 September. */
export function rangeFor(preset: RangePreset, now = new Date()): DateRange {
  const to = new Date(now);
  let from: Date;
  if (preset === "year") {
    const year = now.getUTCMonth() >= 8 ? now.getUTCFullYear() : now.getUTCFullYear() - 1;
    from = new Date(Date.UTC(year, 8, 1));
  } else {
    const days = preset === "7d" ? 7 : preset === "30d" ? 30 : 90;
    from = new Date(now.getTime() - days * 86_400_000);
  }
  return { from: from.toISOString(), to: to.toISOString() };
}

export function slugFilename(text: string): string {
  return text.replace(/[^A-Za-z0-9]+/g, "-").replace(/^-|-$/g, "") || "export";
}
