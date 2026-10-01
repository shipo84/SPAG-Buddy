# Deploy the teacher website

Step-by-step instructions for putting the SPAG Buddy teacher dashboard live. Written so another person or AI assistant can follow them without guessing.

The website lives in `web/`. It is a Next.js 16 app. It talks only to the Supabase Edge Function in `backend/` — it never connects to Postgres itself.

**Using WordPress, or not using Supabase?** Stop here and read [`docs/wordpress-without-supabase.md`](wordpress-without-supabase.md) first. WordPress cannot host this Next.js app as a theme or plugin, and the current backend assumes Supabase.

## What you need

1. A **Supabase** project in the **London (`eu-west-2`)** region (pupil data should stay in the UK).
2. Somewhere to host Next.js. **Vercel** (London region) is the simplest. A Node host that can run `next start` also works.
3. A custom domain for the teacher site, for example `teachers.yourschool.sch.uk` or `spag.yourdomain.com`.
4. Access to this repository, Node 20+, and the [Supabase CLI](https://supabase.com/docs/guides/cli).

Do **not** turn on demo mode in production. Demo mode uses made-up pupils and never talks to Supabase.

---

## Part A — Set up Supabase (backend)

Work from the `backend/` folder of this repo.

### A1. Create the project

1. At [supabase.com](https://supabase.com), create a new project.
2. Choose region **West Europe (London)** / `eu-west-2`.
3. Note the project ref (the subdomain of `https://<ref>.supabase.co`).
4. From **Project Settings → API**, copy:
   - Project URL
   - `anon` `public` key (safe in the browser)
   - `service_role` key (server only — never put this in `web/`)

### A2. Apply the database and seed content

```bash
cd backend
npm run seed
npx supabase login
npx supabase link --project-ref <ref>
npx supabase db push
# Load curriculum content (objectives, questions, spelling lists):
npx supabase db execute --file supabase/seed.sql
# Or, if that command is unavailable:
# psql "$DATABASE_URL" -f supabase/seed.sql
```

`$DATABASE_URL` is the Postgres connection string from **Project Settings → Database**.

### A3. Enable the nightly purge

In the Supabase dashboard: **Database → Extensions → enable `pg_cron`**.

The migration schedules `purge_expired_data()` at 02:30 UTC when the extension is available. Confirm with:

```sql
select jobname, schedule, command from cron.job where jobname = 'spag-buddy-purge';
```

### A4. Deploy the Edge Function

```bash
npx supabase functions deploy api --no-verify-jwt
npx supabase secrets set ALLOWED_ORIGINS=https://YOUR-TEACHER-SITE-DOMAIN
```

`--no-verify-jwt` is required: pupil device tokens are not Supabase JWTs. Teacher routes still check the teacher's JWT inside the function.

Replace `YOUR-TEACHER-SITE-DOMAIN` with the real origin, for example `https://teachers.example.sch.uk`. Use a comma-separated list if you also need localhost during setup:

```bash
npx supabase secrets set ALLOWED_ORIGINS=https://teachers.example.sch.uk,http://localhost:3000
```

### A5. Configure Auth for teachers

In the Supabase dashboard → **Authentication**:

1. **Providers → Email**: enable Email. Prefer magic links (OTP). Disable email confirmations that block first sign-in if you want teachers to get in on the first click.
2. **URL configuration**:
   - Site URL: `https://YOUR-TEACHER-SITE-DOMAIN`
   - Redirect URLs: add
     - `https://YOUR-TEACHER-SITE-DOMAIN/auth/callback`
     - `http://localhost:3000/auth/callback` (for local testing)
3. Optionally restrict sign-ups to school domains under Auth settings / email allow list if your plan supports it.

### A6. Optional: over-the-air question updates for iPads

```bash
# Create a public Storage bucket named "content", then:
npm run upload-content
npx supabase secrets set CONTENT_BASE_URL=https://<ref>.supabase.co/storage/v1/object/public/content
```

---

## Part B — Deploy the Next.js website

Work from the `web/` folder.

### B1. Environment variables

Copy `web/.env.example`. In production set these on the host (Vercel: Project → Settings → Environment Variables):

| Variable | Value | Required |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://<ref>.supabase.co` | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | the `anon` public key | Yes |
| `NEXT_PUBLIC_API_URL` | leave empty, or set to `https://<ref>.supabase.co/functions/v1/api` | Optional |
| `NEXT_PUBLIC_DEMO_MODE` | `false` or omit | Yes — must not be `true` live |

Never put the `service_role` key in the website.

### B2. Deploy on Vercel (recommended)

1. Import this GitHub repo into Vercel.
2. Set **Root Directory** to `web`.
3. Framework: Next.js (auto-detected). Build command `npm run build`, output default.
4. Set the environment variables from B1 for Production (and Preview if you want).
5. Under **Settings → Regions**, prefer a London / EU region so teacher traffic stays near the database.
6. Deploy.
7. Attach your custom domain and wait for HTTPS.
8. Go back to **A5** and **A4**: update Auth redirect URLs and `ALLOWED_ORIGINS` to the live domain.

### B3. Deploy on any Node host instead

```bash
cd web
npm ci
npm run build
# Set the env vars from B1 in the process environment, then:
npm run start
# Listens on port 3000 by default. Put Nginx/Caddy in front with HTTPS.
```

### B4. Smoke test after deploy

1. Open `https://YOUR-TEACHER-SITE-DOMAIN/sign-in`.
2. Enter a school email; click the magic link in the inbox.
3. Complete onboarding (name + school).
4. Create a class → add two first names → print login cards (QR codes should appear).
5. Open the class overview: empty heat map is fine until iPads sync.
6. Open `/privacy` and confirm it loads.
7. Confirm `NEXT_PUBLIC_DEMO_MODE` is off: there must be **no** yellow "Demo mode" banner.

---

## Part C — Point the iPad app at the same backend

In Xcode, set the build setting:

```
SPAG_API_BASE_URL = https://<ref>.supabase.co/functions/v1/api
```

Empty means offline-only. Once set, pupils can join with the class code / picture / PIN (or the QR on the login card) and answers will upload.

---

## Common failures

| Symptom | Likely cause |
| --- | --- |
| Sign-in link opens then says it expired | Missing `/auth/callback` in Supabase Redirect URLs, or Site URL wrong |
| API calls fail with CORS / blocked | `ALLOWED_ORIGINS` does not include the live origin (scheme + host, no trailing slash) |
| "Sign in required" on every page | `NEXT_PUBLIC_SUPABASE_URL` / anon key wrong, or cookies blocked |
| Classes page empty forever after sign-in | Edge Function not deployed, or `NEXT_PUBLIC_API_URL` pointing at the wrong place |
| Yellow "Demo mode" banner live | `NEXT_PUBLIC_DEMO_MODE=true` — turn it off and redeploy |
| Pupil cannot join from iPad | Function not deployed with `--no-verify-jwt`, class archived, or wrong API URL in the app |
| Seed / questions missing | Forgot `supabase/seed.sql` after `db push` |

---

## Files Claude (or you) should read while setting this up

| File | Why |
| --- | --- |
| `web/.env.example` | Exact env var names |
| `web/README.md` | App overview and local demo |
| `web/lib/supabase.ts` | How the browser creates the Supabase client |
| `web/lib/api.ts` | Switches between live API and demo mode |
| `web/app/auth/callback/page.tsx` | Magic-link landing page — redirect URL must match |
| `backend/README.md` | CLI commands, API map, security model |
| `backend/supabase/functions/api/index.ts` | Entry point of the Edge Function |
| `docs/pilot-checklist.md` | Broader go-live checklist including privacy |
| `docs/privacy/` | Notices and DPA before a school pilot |

---

## Prompt you can paste into Claude

```
You are helping me deploy the SPAG Buddy teacher website from this repo.

Read these files first, in order:
1. docs/deploy-teacher-website.md
2. web/.env.example
3. web/README.md
4. backend/README.md
5. docs/pilot-checklist.md (Website + Backend sections)

Then:
- Ask me for: my intended live domain, whether I already have a Supabase project, and whether I want Vercel or another host.
- Follow docs/deploy-teacher-website.md Parts A then B.
- Prefer London/UK regions.
- Never put the Supabase service_role key in the web app.
- Keep NEXT_PUBLIC_DEMO_MODE false for production.
- After deploy, walk me through the smoke test in section B4.

Do not change application code unless a deploy step fails and a config fix is not enough. If you must change code, explain why first.
```
