"use client";

import type { ReactNode } from "react";
import { avatar } from "@/lib/content";
import { LEVEL_ORDER, LEVELS, RANGE_PRESETS, type RangePreset } from "@/lib/format";
import type { Level } from "@/lib/types";

export function Avatar({ avatarKey }: { avatarKey: string }) {
  const a = avatar(avatarKey);
  return (
    <span className="avatar" role="img" aria-label={a.name}>
      {a.emoji}
    </span>
  );
}

export function PupilName({ name, avatarKey }: { name: string; avatarKey: string }) {
  return (
    <span className="pupil-name">
      <Avatar avatarKey={avatarKey} />
      {name}
    </span>
  );
}

export function LevelPill({ level }: { level: Level }) {
  const info = LEVELS[level];
  return <span className={`pill ${info.className}`}>{info.label}</span>;
}

export function Legend() {
  return (
    <div className="legend" aria-label="Key">
      {(["secure", "developing", "needsSupport", "notStarted"] as Level[]).map((level) => (
        <span key={level} className="row" style={{ gap: "0.35rem" }}>
          <span className={`heat-cell ${LEVELS[level].className}`} style={{ width: 20, height: 20 }} aria-hidden>
            {LEVELS[level].short}
          </span>
          {LEVELS[level].label}
        </span>
      ))}
    </div>
  );
}

/** A stacked bar showing how many pupils are at each level. */
export function LevelBar({ levels }: { levels: Record<Level, number> }) {
  const total = LEVEL_ORDER.reduce((sum, level) => sum + levels[level], 0) || 1;
  const colours: Record<Level, string> = {
    needsSupport: "var(--support)",
    developing: "#e0a526",
    secure: "var(--secure)",
    notStarted: "transparent",
  };
  const label = LEVEL_ORDER.map((l) => `${levels[l]} ${LEVELS[l].label.toLowerCase()}`).join(", ");
  return (
    <div className="bar" role="img" aria-label={label} title={label}>
      {LEVEL_ORDER.map((level) => (
        <span key={level} style={{ width: `${(levels[level] / total) * 100}%`, background: colours[level] }} />
      ))}
    </div>
  );
}

export function RangePicker({ value, onChange }: { value: RangePreset; onChange: (value: RangePreset) => void }) {
  return (
    <div className="segmented" role="group" aria-label="Date range">
      {RANGE_PRESETS.map((preset) => (
        <button key={preset.value} type="button" aria-pressed={value === preset.value} onClick={() => onChange(preset.value)}>
          {preset.label}
        </button>
      ))}
    </div>
  );
}

export function Stat({ label, value, note }: { label: string; value: ReactNode; note?: ReactNode }) {
  return (
    <div className="card stat">
      <span className="label">{label}</span>
      <span className="value">{value}</span>
      {note ? <span className="small muted">{note}</span> : null}
    </div>
  );
}

export function Loading({ label = "Loading…" }: { label?: string }) {
  return (
    <p className="loading" role="status">
      {label}
    </p>
  );
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="alert error" role="alert">
      {message}{" "}
      {onRetry ? (
        <button type="button" className="btn link" onClick={onRetry}>
          Try again
        </button>
      ) : null}
    </div>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="empty">{children}</div>;
}
