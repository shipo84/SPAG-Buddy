"use client";

import type { LoginCards } from "./types";

/**
 * PINs are only ever shown once, straight after they are created. They are kept in sessionStorage just long enough
 * to print, so they disappear when the tab is closed.
 */
const key = (classId: string) => `spag-buddy:login-cards:${classId}`;

export function saveLoginCards(classId: string, cards: LoginCards) {
  sessionStorage.setItem(key(classId), JSON.stringify(cards));
}

export function loadLoginCards(classId: string): LoginCards | null {
  const raw = sessionStorage.getItem(key(classId));
  if (!raw) return null;
  try {
    return JSON.parse(raw) as LoginCards;
  } catch {
    return null;
  }
}

export function clearLoginCards(classId: string) {
  sessionStorage.removeItem(key(classId));
}
