import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { bearerToken, HttpError, notFound, unauthorised } from "./http.ts";
import { sha256Hex } from "./codes.ts";

function env(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not set`);
  return value;
}

/** Bypasses Row Level Security. Only use after checking who the caller is. */
export function serviceClient(): SupabaseClient {
  return createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Acts as the signed-in teacher, so Row Level Security applies to every query. */
export function userClient(req: Request): SupabaseClient {
  const token = bearerToken(req);
  if (!token) throw unauthorised();
  return createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function check<T>(result: { data: T; error: { message: string; code?: string } | null }): T {
  if (result.error) {
    if (result.error.code === "PGRST116") throw notFound();
    throw new HttpError(500, "database_error", result.error.message);
  }
  return result.data;
}

export interface PupilSession {
  pupilId: string;
  classId: string;
  deviceId: string;
}

/** Resolves a pupil device token. Tokens are revoked when the pupil is deleted or the class archived. */
export async function authenticatePupil(req: Request, db: SupabaseClient): Promise<PupilSession> {
  const token = bearerToken(req);
  if (!token) throw unauthorised("Device token required");
  const hash = await sha256Hex(token);
  const { data, error } = await db
    .from("devices")
    .select("id, pupil_id, revoked_at, pupils!inner(class_id, classes!inner(archived_at))")
    .eq("token_hash", hash)
    .maybeSingle();
  if (error) throw new HttpError(500, "database_error", error.message);
  // deno-lint-ignore no-explicit-any
  const row = data as any;
  if (!row || row.revoked_at || row.pupils.classes.archived_at) throw unauthorised("This device is no longer linked to a class");
  await db.from("devices").update({ last_seen_at: new Date().toISOString() }).eq("id", row.id);
  return { pupilId: row.pupil_id, classId: row.pupils.class_id, deviceId: row.id };
}

export interface Teacher {
  id: string;
  schoolId: string | null;
  displayName: string;
}

export async function authenticateTeacher(req: Request, db: SupabaseClient): Promise<{ userId: string; teacher: Teacher | null }> {
  const { data, error } = await db.auth.getUser();
  if (error || !data.user) throw unauthorised();
  const { data: row } = await db.from("teachers").select("id, school_id, display_name").eq("id", data.user.id).maybeSingle();
  return {
    userId: data.user.id,
    teacher: row ? { id: row.id, schoolId: row.school_id, displayName: row.display_name } : null,
  };
}

export async function requireTeacher(req: Request, db: SupabaseClient): Promise<Teacher> {
  const { teacher } = await authenticateTeacher(req, db);
  if (!teacher) throw new HttpError(403, "profile_required", "Finish setting up your teacher profile first");
  return teacher;
}

export interface ClassRow {
  id: string;
  name: string;
  year_group: number;
  class_code: string;
  archived_at: string | null;
  created_at: string;
  school_id: string | null;
}

export const CLASS_COLUMNS = "id, name, year_group, class_code, archived_at, created_at, school_id";

/** Row Level Security only returns the class if the caller teaches it. */
export async function requireClass(db: SupabaseClient, classId: string): Promise<ClassRow> {
  const { data, error } = await db.from("classes").select(CLASS_COLUMNS).eq("id", classId).maybeSingle();
  if (error) throw new HttpError(500, "database_error", error.message);
  if (!data) throw notFound("Class not found");
  return data as ClassRow;
}
