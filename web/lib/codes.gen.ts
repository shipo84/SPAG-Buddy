// Copied from backend/supabase/functions/_shared/codes.ts by backend/scripts/generate-seed.mjs. Do not edit.
/** No I, O, 0 or 1, which children confuse. Matches the check constraint on classes.class_code. */
export const CLASS_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function randomIndex(max: number): number {
  // Rejection sampling avoids modulo bias.
  const limit = Math.floor(0x1_0000_0000 / max) * max;
  const buffer = new Uint32Array(1);
  while (true) {
    crypto.getRandomValues(buffer);
    if (buffer[0] < limit) return buffer[0] % max;
  }
}

export function generateClassCode(): string {
  let code = "";
  for (let i = 0; i < 6; i++) code += CLASS_CODE_ALPHABET[randomIndex(CLASS_CODE_ALPHABET.length)];
  return code;
}

/** Four digits, avoiding PINs a child could guess such as 1111 or 1234. */
export function generatePin(): string {
  while (true) {
    const pin = String(randomIndex(10_000)).padStart(4, "0");
    if (!isGuessablePin(pin)) return pin;
  }
}

export function isGuessablePin(pin: string): boolean {
  if (/^(\d)\1{3}$/.test(pin)) return true;
  const digits = [...pin].map(Number);
  const ascending = digits.every((d, i) => i === 0 || d === digits[i - 1] + 1);
  const descending = digits.every((d, i) => i === 0 || d === digits[i - 1] - 1);
  return ascending || descending;
}

export function generateDeviceToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export function pickUnusedAvatar(all: readonly string[], used: Set<string>): string | null {
  const free = all.filter((key) => !used.has(key));
  return free.length ? free[randomIndex(free.length)] : null;
}

export function joinUrl(classCode: string, avatarKey: string, pin: string): string {
  const params = new URLSearchParams({ class: classCode, picture: avatarKey, pin });
  return `spagbuddy://join?${params}`;
}
