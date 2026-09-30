/** Splits a pasted list of names on new lines or commas, tidying spaces and dropping blanks and repeats. */
export function parseNames(text: string): string[] {
  const seen = new Set<string>();
  return text
    .split(/[\n,]/)
    .map((n) => n.trim().replace(/\s+/g, " "))
    .filter((n) => {
      const k = n.toLocaleLowerCase("en-GB");
      if (!n || seen.has(k)) return false;
      seen.add(k);
      return true;
    });
}

/** Mirrors pupilName() in the API so mistakes are caught before sending. */
export function pupilNameProblem(name: string): string | null {
  if (name.length > 30) return `"${name}" is too long. Use up to 30 characters.`;
  if (/[@\d]/.test(name)) return `"${name}" should be a first name or nickname only.`;
  return null;
}
