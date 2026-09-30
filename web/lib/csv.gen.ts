// Copied from backend/supabase/functions/_shared/csv.ts by backend/scripts/generate-seed.mjs. Do not edit.
/**
 * Escapes a CSV cell. Cells that start with =, +, - or @ are prefixed with an apostrophe so a pupil's typed
 * answer cannot run as a formula when the export is opened in Excel.
 */
export function csvCell(value: unknown): string {
  let text = value === null || value === undefined ? "" : String(value);
  if (/^[=+\-@\t\r]/.test(text)) text = `'${text}`;
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export function toCsv(header: string[], rows: unknown[][]): string {
  return [header, ...rows].map((row) => row.map(csvCell).join(",")).join("\r\n") + "\r\n";
}
