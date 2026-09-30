import { type Api, ApiError, type DateRange } from "./types";

type TokenSource = () => Promise<string | null>;

/** Talks to the `api` Edge Function. Every request carries the teacher's Supabase session token. */
export function createHttpApi(baseUrl: string, token: TokenSource, fetcher: typeof fetch = fetch): Api {
  async function request(method: string, path: string, body?: unknown): Promise<Response> {
    const accessToken = await token();
    if (!accessToken) throw new ApiError(401, "unauthorised", "Please sign in again.");
    const response = await fetcher(`${baseUrl}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${accessToken}`,
        ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      cache: "no-store",
    });
    if (!response.ok) {
      let code = "server_error";
      let message = "Something went wrong. Please try again.";
      try {
        const payload = (await response.json()) as { error?: string; message?: string };
        code = payload.error ?? code;
        message = payload.message ?? message;
      } catch {
        // Not JSON, so keep the generic message.
      }
      throw new ApiError(response.status, code, message);
    }
    return response;
  }

  const call = async <T>(method: string, path: string, body?: unknown) => (await (await request(method, path, body)).json()) as T;
  const q = (range: DateRange) => `?${new URLSearchParams({ from: range.from, to: range.to })}`;
  const id = encodeURIComponent;

  return {
    demo: false,
    async me() {
      try {
        return await call("GET", "/teacher/me");
      } catch (error) {
        if (error instanceof ApiError && error.code === "profile_required") return null;
        throw error;
      }
    },
    async saveProfile(input) {
      await call("POST", "/teacher/profile", input);
    },
    async listClasses() {
      return (await call<{ classes: never[] }>("GET", "/classes")).classes;
    },
    async createClass(input) {
      return (await call<{ class: never }>("POST", "/classes", input)).class;
    },
    getClass: (classId) => call("GET", `/classes/${id(classId)}`),
    async updateClass(classId, patch) {
      return (await call<{ class: never }>("PATCH", `/classes/${id(classId)}`, patch)).class;
    },
    async deleteClass(classId) {
      await call("DELETE", `/classes/${id(classId)}`);
    },
    addPupils: (classId, names) => call("POST", `/classes/${id(classId)}/pupils`, { names }),
    loginCards: (classId, pupilIds) => call("POST", `/classes/${id(classId)}/login-cards`, pupilIds ? { pupilIds } : {}),
    async renamePupil(pupilId, displayName) {
      await call("PATCH", `/pupils/${id(pupilId)}`, { displayName });
    },
    async deletePupil(pupilId) {
      await call("DELETE", `/pupils/${id(pupilId)}`);
    },
    async listAssignments(classId) {
      return (await call<{ assignments: never[] }>("GET", `/classes/${id(classId)}/assignments`)).assignments;
    },
    async createAssignment(input) {
      await call("POST", "/assignments", input);
    },
    async archiveAssignment(assignmentId) {
      await call("DELETE", `/assignments/${id(assignmentId)}`);
    },
    classAnalytics: (classId, range) => call("GET", `/classes/${id(classId)}/analytics${q(range)}`),
    objectiveDetail: (classId, code, range) => call("GET", `/classes/${id(classId)}/objectives/${id(code)}${q(range)}`),
    pupilProgress: (pupilId, range) => call("GET", `/pupils/${id(pupilId)}/progress${q(range)}`),
    sats: (classId, range) => call("GET", `/classes/${id(classId)}/sats${q(range)}`),
    async exportCsv(classId, range) {
      const response = await request("GET", `/classes/${id(classId)}/export.csv${q(range)}`);
      const disposition = response.headers.get("Content-Disposition") ?? "";
      const filename = /filename="([^"]+)"/.exec(disposition)?.[1] ?? "spag-buddy-export.csv";
      return { filename, blob: await response.blob() };
    },
  };
}
