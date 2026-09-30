import type { DateRange } from "@/lib/types";

interface Day {
  day: string;
  attempts: number;
  correct: number;
}

const dayLabel = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });

/** Fills in days with no practice so gaps show up on the chart. */
export function fillDays(daily: Day[], range: DateRange, maxDays = 120): Day[] {
  const byDay = new Map(daily.map((d) => [d.day, d]));
  const london = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/London" });
  const end = new Date(range.to).getTime();
  let start = new Date(range.from).getTime();
  if ((end - start) / 86_400_000 > maxDays) start = end - maxDays * 86_400_000;
  const days: Day[] = [];
  const seen = new Set<string>();
  for (let t = start; t < end; t += 86_400_000) {
    const key = london.format(new Date(t));
    if (seen.has(key)) continue;
    seen.add(key);
    days.push(byDay.get(key) ?? { day: key, attempts: 0, correct: 0 });
  }
  return days;
}

export function DailyChart({ daily, range }: { daily: Day[]; range: DateRange }) {
  const days = fillDays(daily, range);
  const width = 720;
  const height = 180;
  const pad = { top: 10, right: 8, bottom: 24, left: 30 };
  const max = Math.max(10, ...days.map((d) => d.attempts));
  const barWidth = (width - pad.left - pad.right) / Math.max(days.length, 1);
  const y = (value: number) => pad.top + (height - pad.top - pad.bottom) * (1 - value / max);
  const labelEvery = Math.ceil(days.length / 8);
  const total = days.reduce((s, d) => s + d.attempts, 0);
  const active = days.filter((d) => d.attempts > 0).length;

  return (
    <figure style={{ margin: 0 }}>
      <svg viewBox={`0 0 ${width} ${height}`} width="100%" role="img" aria-label={`${total} answers over ${active} days of practice`}>
        {[0, 0.5, 1].map((f) => (
          <g key={f}>
            <line x1={pad.left} x2={width - pad.right} y1={y(max * f)} y2={y(max * f)} stroke="#e3e2ee" />
            <text x={pad.left - 6} y={y(max * f) + 4} fontSize="10" textAnchor="end" fill="#5d5b72">
              {Math.round(max * f)}
            </text>
          </g>
        ))}
        {days.map((d, i) => {
          const x = pad.left + i * barWidth + barWidth * 0.15;
          const w = barWidth * 0.7;
          return (
            <g key={d.day}>
              <title>{`${dayLabel.format(new Date(`${d.day}T00:00:00Z`))}: ${d.correct} of ${d.attempts} right`}</title>
              <rect x={x} y={y(d.attempts)} width={w} height={y(0) - y(d.attempts)} fill="#f3b8b1" rx="2" />
              <rect x={x} y={y(d.correct)} width={w} height={y(0) - y(d.correct)} fill="#13733f" rx="2" />
              {i % labelEvery === 0 ? (
                <text x={x + w / 2} y={height - 8} fontSize="10" textAnchor="middle" fill="#5d5b72">
                  {dayLabel.format(new Date(`${d.day}T00:00:00Z`))}
                </text>
              ) : null}
            </g>
          );
        })}
      </svg>
      <figcaption className="legend" style={{ marginTop: "0.25rem" }}>
        <span className="row" style={{ gap: "0.35rem" }}>
          <span style={{ width: 12, height: 12, background: "#13733f", borderRadius: 3, display: "inline-block" }} /> Right
        </span>
        <span className="row" style={{ gap: "0.35rem" }}>
          <span style={{ width: 12, height: 12, background: "#f3b8b1", borderRadius: 3, display: "inline-block" }} /> Not right yet
        </span>
      </figcaption>
    </figure>
  );
}
