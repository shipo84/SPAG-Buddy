# WordPress hosting (no Supabase)

The teacher dashboard in `web/` is a **Next.js** app. The iPad and that dashboard both expect the **HTTP API** documented in `backend/README.md`. Today that API is implemented with **Supabase** (Postgres + Auth + one Edge Function).

**WordPress cannot run this stack as-is.** You cannot upload `web/` as a WordPress theme or plugin and have it work. You also cannot "just turn off Supabase" without replacing everything it does: database, teacher sign-in, pupil join, attempt upload, analytics and CSV export.

This note is for Claude (or a developer) when the public site is WordPress and Supabase is not an option.

---

## Pick one approach

### Option 1 — Keep WordPress as the marketing site only (smallest change)

Use WordPress for the school/product brochure site. Host the teacher app separately (Vercel, Railway, a small UK/EU VPS running Node). Link to it from WordPress ("Teachers sign in").

- Backend: still needs the API. Easiest is Supabase London as in `docs/deploy-teacher-website.md`.
- If Supabase is ruled out entirely, you still need **some** Postgres (or MySQL) host plus the API from Option 2 or 3.

**Use this if:** you only meant "our public website is WordPress", not "teachers must live inside wp-admin".

### Option 2 — WordPress plugin that implements the same API (no Supabase)

Build a custom WordPress plugin that:

1. Creates the tables (or uses a separate database) matching the shape in `backend/supabase/migrations/20260930000000_init.sql`.
2. Exposes the same routes under something like `https://yoursite.sch.uk/wp-json/spag-buddy/v1/...` (or a plain `/api/...` rewrite).
3. Signs teachers in with WordPress users (school staff accounts) and issues a bearer token the Next.js app (or a rebuilt PHP UI) can send.
4. Implements pupil join (class code + picture + PIN), attempt upload (idempotent on `clientAttemptId`), assignments, analytics and CSV export with the same JSON shapes the iPad already expects.

Then either:

- **A.** Host Next.js on a subdomain (`teachers.…`) and point `NEXT_PUBLIC_API_URL` at the WordPress API, replacing the Supabase auth client with WordPress cookie/token auth, **or**
- **B.** Rebuild the teacher screens as WordPress admin pages / a React app enqueued in WP, calling the same plugin API.

This is a **rebuild of `backend/`**, not a deploy of the current `backend/` folder. Plan for substantial work: auth, RLS-equivalent access checks, PIN hashing, lockouts, retention cron, and every route in `backend/README.md`.

**Use this if:** teachers must stay on the WordPress domain and you will not use Supabase.

### Option 3 — Demo / brochure only on WordPress (no live pupil data)

Run `web` with `NEXT_PUBLIC_DEMO_MODE=true` on a Node host, or export static marketing pages into WordPress. Fine for showing stakeholders the UI. **Not** for real classes: nothing is saved, PINs and classes reset on reload.

---

## What any non-Supabase backend must provide

The iPad app does not know about WordPress or Supabase. It only needs:

| Need | Detail |
| --- | --- |
| Base URL | Set in Xcode as `SPAG_API_BASE_URL` (today: `…/functions/v1/api`) |
| Pupil routes | `POST /pupil/join`, `GET /assignments`, `POST /attempts`, `GET /content/manifest` |
| Auth for pupils | Bearer device token returned from join (not a WordPress cookie) |
| Teacher routes | Everything under teachers in `backend/README.md` |
| Privacy | UK hosting, retention (24 months answers / 12 months archived classes), no pupil emails |

Copy the request and response shapes from:

- `backend/supabase/functions/api/pupil.ts`
- `backend/supabase/functions/api/teacher.ts`
- `backend/supabase/functions/tests/api.test.ts`
- `web/lib/types.ts` and `web/lib/http-api.ts`

Mastery and SATs banding rules must stay identical: `backend/supabase/functions/_shared/analytics.ts` (also copied to `web/lib/analytics.gen.ts`).

---

## Recommended path for "WordPress site, no Supabase"

1. Confirm with the owner: is WordPress only the public site (Option 1), or must the teacher UI live inside WordPress (Option 2)?
2. If Option 1: deploy Node + a managed Postgres in London/EU; either keep Supabase or port the Edge Function to a small Node/PHP API on Postgres. Point a subdomain at the teacher app; link from WordPress.
3. If Option 2: scaffold a plugin `spag-buddy` that registers REST routes matching `backend/README.md`, migrate schema to MySQL/`dbDelta` or an external Postgres, replace `web/lib/supabase.ts` auth with WP application passwords or JWT, set `NEXT_PUBLIC_API_URL` to the WP REST base (or rebuild UI in WP).
4. Keep the iPad on the same API contract so you do not rewrite Swift.

Do **not** paste Next.js into a WordPress theme. Do **not** store pupil answers as WordPress posts or user meta.

---

## Prompt to paste into Claude

```
Our public site is WordPress. We are not using Supabase.

Read first:
1. docs/wordpress-without-supabase.md
2. docs/deploy-teacher-website.md (so you know what the current stack assumes)
3. backend/README.md (API contract the iPad and teacher UI need)
4. web/lib/http-api.ts and web/lib/types.ts
5. backend/supabase/migrations/20260930000000_init.sql (data model)

Ask me which option from docs/wordpress-without-supabase.md I want:
- Option 1: WordPress = marketing only; teacher app on a subdomain
- Option 2: WordPress plugin implements the API (and possibly the teacher UI)
- Option 3: demo only

Then propose a concrete plan for that option only. Prefer UK/EU hosting. Do not put pupil data in wp_posts. Preserve the existing HTTP API shapes so the iOS app keeps working. Do not start a full rewrite until I confirm the option and the target domain/hosting.
```

---

## Files that matter most for a port

| File | Role |
| --- | --- |
| `backend/README.md` | Full API map |
| `backend/supabase/migrations/20260930000000_init.sql` | Tables, login, analytics SQL, retention |
| `backend/supabase/functions/api/pupil.ts` | iPad endpoints |
| `backend/supabase/functions/api/teacher.ts` | Teacher endpoints |
| `backend/supabase/functions/_shared/analytics.ts` | Mastery / SATs rules |
| `web/lib/http-api.ts` | How the dashboard calls the API |
| `web/lib/demo-api.ts` | In-memory reference implementation of the same API |
| `docs/privacy/retention-policy.md` | Deletion rules any host must keep |
