# SPAG Buddy for teachers (web)

A Next.js dashboard where teachers set up classes, print pupil login cards and see how their class is doing. It talks to the `api` Edge Function in `backend/`. It never reads the database directly, so every request goes through the same checks as the iPad app.

## Try it without a backend

```bash
cd web
npm install
npm run demo        # http://localhost:3000, made-up pupils, no sign-in
```

Demo mode (`NEXT_PUBLIC_DEMO_MODE=true`) swaps the API for an in-memory copy that uses the same mastery, analytics, code and CSV rules as the server. These are generated from `backend/supabase/functions/_shared` by `npm run seed` in `backend/`.

## Run against Supabase

1. Set up the backend (see `backend/README.md`) and deploy the `api` function.
2. Copy `.env.example` to `.env.local` and fill in the project URL and anon key.
3. In Supabase Auth, add `http://localhost:3000/auth/callback` (and your live URL) to the redirect URLs.
4. Set `ALLOWED_ORIGINS` on the Edge Function to this site's origin.
5. Run `npm run dev`.

Teachers sign in with an emailed magic link. The first time, they enter their name and school.

## Put it on the internet

Full step-by-step (Supabase + Vercel/Node + Auth + smoke test), written so another AI assistant can follow it: [`docs/deploy-teacher-website.md`](../docs/deploy-teacher-website.md).

If the public site is WordPress or you will not use Supabase: [`docs/wordpress-without-supabase.md`](../docs/wordpress-without-supabase.md).

## Pages

| Path | What it does |
| --- | --- |
| `/classes` | List and create classes |
| `/classes/[id]` | Overview: totals, skills to focus on, pupils to check in with, heat map, CSV download |
| `/classes/[id]/pupils` | Add pupils by first name, rename, delete, make new PINs |
| `/classes/[id]/login-cards` | Printable cards with class code, picture, PIN and QR code. PINs are shown once |
| `/classes/[id]/assignments` | Set skills or spelling lists for the class or chosen pupils |
| `/classes/[id]/sats` | Year 6 indicative SATs practice guide (not a scaled score) |
| `/classes/[id]/settings` | Rename, change year group, archive, delete with all data |
| `/classes/[id]/objectives/[code]` | Question accuracy and common wrong answers for one skill |
| `/pupils/[id]` | One pupil: daily practice chart, skills, spelling lists, sessions |
| `/privacy` | What is stored, where and for how long |

## Checks

```bash
npm test            # Vitest: shared rules, demo API, HTTP client
npm run typecheck
npm run build
```
