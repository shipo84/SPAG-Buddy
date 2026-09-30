# SPAG Buddy backend

A [Supabase](https://supabase.com) project: Postgres with Row Level Security, Supabase Auth for teachers, and one Edge Function (`api`) that both the iPad app and the teacher website call.

Create the project in the **London (eu-west-2)** region so pupil data stays in the UK.

## Layout

| Path | What it is |
| --- | --- |
| `supabase/migrations/` | Schema, RLS policies, login and analytics SQL functions, retention job |
| `supabase/seed.sql` | Curriculum objectives, spelling lists and questions. Generated, do not edit |
| `supabase/functions/api/` | The Edge Function: `pupil.ts` (iPad routes) and `teacher.ts` (website routes) |
| `supabase/functions/_shared/` | Validation, analytics, CSV export, codes and database helpers |
| `supabase/functions/tests/` | Deno unit tests |
| `scripts/generate-seed.mjs` | Builds `seed.sql`, `_shared/content.gen.ts` and `web/lib/content.gen.json` from the app's content JSON |
| `scripts/test-db.sh` | Runs the migration, seed and RLS checks against a local Postgres |

## Set up

```bash
npm run seed                                  # after any content change
supabase link --project-ref <ref>
supabase db push                              # apply migrations
psql "$SUPABASE_DB_URL" -f supabase/seed.sql  # load or update content
supabase functions deploy api --no-verify-jwt
supabase secrets set ALLOWED_ORIGINS=https://teachers.example.sch.uk
```

Optional, for over-the-air question updates: create a public storage bucket called `content`, run `npm run upload-content`, then `supabase secrets set CONTENT_BASE_URL=https://<ref>.supabase.co/storage/v1/object/public/content`.

In the Supabase dashboard: enable the `pg_cron` extension so `purge_expired_data()` runs nightly (the migration schedules it when the extension is available), and under Auth restrict sign-ups to your schools' email domains.

## Tests

```bash
npm test          # Deno unit tests (validation, analytics, CSV, router, HTTP handler)
npm run check     # Type-check the Edge Function
npm run test:db   # Needs a local Postgres superuser (PGHOST/PGUSER); checks pupil_join, RLS and deletion
```

## API

Base URL: `https://<ref>.supabase.co/functions/v1/api`. Paths may also be prefixed with `/v1`.

### Pupil devices

The iPad sends `Authorization: Bearer <device token>` except when joining.

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/pupil/join` | `{ classCode, avatarKey, pin }` returns the pupil's name, year group and a device token. 5 wrong PINs locks the pupil for 15 minutes; 30 failures locks the class. |
| GET | `/content/manifest` | Latest content version and download URLs |
| GET | `/assignments` | Open work for the pupil (whole class or their group) |
| POST | `/attempts` | Up to 200 answers. Idempotent on `clientAttemptId`. Returns `accepted` and permanently `rejected` ids. |

### Teachers

The website sends the Supabase Auth access token. Every query runs as the teacher, so RLS limits it to their classes.

| Method | Path |
| --- | --- |
| GET / POST | `/teacher/me`, `/teacher/profile` |
| GET / POST | `/classes` |
| GET / PATCH / DELETE | `/classes/{id}` (PATCH `archived: true` stops pupils syncing; DELETE removes everything) |
| POST | `/classes/{id}/pupils` (`{ names: [...] }`, returns login cards) |
| POST | `/classes/{id}/login-cards` (new PINs for reprinting; joined iPads keep working) |
| PATCH / DELETE | `/pupils/{id}` |
| GET | `/classes/{id}/assignments`; POST `/assignments`; DELETE `/assignments/{id}` |
| GET | `/classes/{id}/analytics?from&to` (heat map data) |
| GET | `/classes/{id}/objectives/{code}?from&to` (question accuracy and common wrong answers) |
| GET | `/pupils/{id}/progress?from&to` |
| GET | `/classes/{id}/sats?from&to` (Year 6 readiness, indicative only) |
| GET | `/classes/{id}/export.csv?from&to` |

## Security model

- Pupils have no Supabase account. A device token (random, 256-bit) is created at join; only its SHA-256 hash is stored.
- PINs are stored as bcrypt hashes and are only shown to the teacher when cards are printed.
- `devices` and `audit_log` have RLS enabled with no policies, so only the service role can read them.
- Teachers cannot read `pupils.pin_hash` (column grants) or insert attempts.
- Deletions and PIN resets are written to `audit_log`.
