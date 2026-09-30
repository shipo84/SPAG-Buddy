// SPAG Buddy API (Supabase Edge Function).
// Deploy with: supabase functions deploy api --no-verify-jwt
// Pupil routes use device tokens and teacher routes verify the Supabase Auth JWT themselves.

import { corsHeaders, errorResponse, HttpError, json } from "../_shared/http.ts";
import { routePath, Router } from "../_shared/router.ts";
import { pupilRoutes } from "./pupil.ts";
import { teacherRoutes } from "./teacher.ts";

export const router = new Router();
router.get("/health", () => Promise.resolve(json({ ok: true })));
pupilRoutes(router);
teacherRoutes(router);

export async function handle(req: Request): Promise<Response> {
  const cors = corsHeaders(req.headers.get("Origin"));
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

  let response: Response;
  try {
    const url = new URL(req.url);
    const match = router.match(req.method, routePath(url.pathname));
    if (match === null) throw new HttpError(404, "not_found", "No such endpoint");
    if (match === "method_not_allowed") throw new HttpError(405, "method_not_allowed", "Method not allowed");
    response = await match.handler({ req, url, params: match.params });
  } catch (error) {
    response = errorResponse(error);
  }
  for (const [key, value] of Object.entries(cors)) response.headers.set(key, value);
  return response;
}

if (import.meta.main) Deno.serve(handle);
