# SPAG Buddy

SPAG Buddy is a spelling, punctuation and grammar (SPAG) practice app for UK primary pupils in Year 1 to Year 6. It follows the National Curriculum for English (Appendix 1: Spelling, Appendix 2: Vocabulary, Grammar and Punctuation) and includes KS2 SATs GPS-style practice for Year 6.

Teachers use a companion website to set work and see how their class is doing.

## Repository layout

| Path | What it is |
| --- | --- |
| `SPAG Buddy Home/` | The SPAG Buddy Home app target (parents, on-device only) |
| `SPAG Buddy School/` | The SPAG Buddy School app target (classes, syncs to the teacher website) |
| `Packages/SPAGCore/` | Shared Swift package: content, models, quiz engine, progress, theme and shared views (SwiftUI + SwiftData, iOS 17+) |
| `Packages/SPAGSchoolSync/` | School-only Swift package: class login, answer sync, assignments and content updates |
| `Packages/SPAGCore/Sources/SPAGCore/Resources/Content/` | Curriculum objectives, question banks and statutory spelling lists (JSON). This is the single source of truth for content. |
| `Config/` | One `.xcconfig` per app target (bundle ID, display name, app icon) |
| `backend/` | Supabase project: Postgres schema, Row Level Security and the `api` Edge Function |
| `web/` | Teacher website (Next.js) |
| `docs/` | Privacy notices, DPA and DPIA templates, retention policy and pilot checklist |

## How it fits together

1. A teacher signs in to the website with their school email, creates a class and adds pupils (first name or nickname only).
2. The website prints a login card for each pupil with the class code, a picture and a 4-digit PIN (plus a QR code).
3. On the iPad, the pupil types the class code, taps their picture and enters their PIN. The device receives a token for that pupil.
4. Pupils practise offline. Each answer is saved on the device and uploaded in batches when there is a connection.
5. The teacher sees a heat map of pupils against curriculum objectives, common wrong answers, pupil progress and Year 6 SATs readiness.

Pupils can also use the app without a class ("Practise at home"). Nothing leaves the device in that mode.

## iOS apps

One codebase builds two App Store apps. Open `SPAG Buddy.xcodeproj` in Xcode 26 or later and run either scheme:

| Scheme | Bundle ID | Home screen name | Links |
| --- | --- | --- | --- |
| `SPAG Buddy Home` | `Digital-Clubhouse.SPAG-Buddy` (the existing App Store listing) | SPAG Home | `SPAGCore` |
| `SPAG Buddy School` | `Digital-Clubhouse.SPAG-Buddy-School` | SPAG School | `SPAGCore`, `SPAGSchoolSync` |

- Minimum iOS version is 17.0 so older school iPads are supported.
- Each app target injects its `Edition` (`.home` or `.school`) into the SwiftUI environment. Shared views read it with `@Environment(\.edition)` rather than using `#if`.
- Class features reach the shared views through the `ClassServices` protocol in `SPAGCore`. The School app passes `SchoolClassServices`; the Home app passes nothing, so no networking code is linked into it.
- Each edition has its own SwiftData store (`SPAGHome.store`, `SPAGSchool.store`), so the two apps never share data.
- Set the School API URL with `SPAG_API_BASE_URL` in `Config/School.xcconfig` (for example `https:/$()/<project-ref>.supabase.co/functions/v1/api`). If it is empty the School app runs in offline-only mode.
- Pupil device tokens are stored in the Keychain. Practice data is stored locally with SwiftData and is not synced to iCloud.
- Unit tests live in the packages (`SPAGCoreTests`, `SPAGSchoolSyncTests`) and run from each app's Test action on an iOS simulator.

Source layout inside `Packages/SPAGCore/Sources/SPAGCore/`:

- `Models/` SwiftData models (`PupilProfile`, `Attempt`, `Assignment`, `BadgeProgress`) and content types (`Question`, `Objective`, `SpellingList`)
- `Services/` content loading, answer marking, session building, badges, speech, the `ClassServices` protocol and the SwiftData store
- `Views/` onboarding, home, practice, progress and settings screens
- `Theme/` colours, fonts and accessibility settings

`Packages/SPAGSchoolSync/Sources/SPAGSchoolSync/` holds the API client, sync, Keychain, content updater and the join-a-class screen.

## Backend

See [`backend/README.md`](backend/README.md). In short:

```bash
cd backend
npm run seed          # regenerate supabase/seed.sql from the app's content JSON
supabase db push      # apply migrations
supabase functions deploy api --no-verify-jwt
```

Host the Supabase project in the London (`eu-west-2`) region.

## Teacher website

See [`web/README.md`](web/README.md). In short:

```bash
cd web
npm install
cp .env.example .env.local   # add your Supabase URL, anon key and API URL
npm run dev
```

Run `npm run demo` to explore the dashboard with made-up pupils and no backend.

To put the teacher site live, follow [`docs/deploy-teacher-website.md`](docs/deploy-teacher-website.md). If your public site is WordPress or you will not use Supabase, start with [`docs/wordpress-without-supabase.md`](docs/wordpress-without-supabase.md) instead.

## Content

Question banks live in `Packages/SPAGCore/Sources/SPAGCore/Resources/Content/year1.json` to `year6.json`. Objectives are in `objectives.json` and spelling lists in `spelling-lists.json`. After changing content:

1. Run the unit tests (they validate every question).
2. Bump `contentVersion` in `manifest.json`.
3. Run `npm run seed` in `backend/` so the server and the website know about new questions.
4. Run `npm run upload-content` in `backend/` so iPads that are already installed download the new questions.

## Privacy

SPAG Buddy is designed for the UK GDPR and the ICO Age Appropriate Design Code (Children's Code). See [`docs/privacy/`](docs/privacy/). The school is the data controller. No pupil email addresses, photos, location, advertising or third-party analytics are used. Pupils can read what happens to their answers in the app. Before a school pilot, work through [`docs/pilot-checklist.md`](docs/pilot-checklist.md).
