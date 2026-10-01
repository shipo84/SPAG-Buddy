# SPAG Buddy

SPAG Buddy is a spelling, punctuation and grammar (SPAG) practice app for UK primary pupils in Year 1 to Year 6. It follows the National Curriculum for English (Appendix 1: Spelling, Appendix 2: Vocabulary, Grammar and Punctuation) and includes KS2 SATs GPS-style practice for Year 6.

Teachers use a companion website to set work and see how their class is doing.

## Repository layout

| Path | What it is |
| --- | --- |
| `SPAGCore/` | Shared iOS and iPadOS code (SwiftUI + SwiftData, iOS 17+) built into both apps |
| `SPAGCore/Resources/Content/` | Curriculum objectives, question banks and statutory spelling lists (JSON). This is the single source of truth for content. |
| `SPAG Buddy Home/` | SPAG Buddy Home app: strictly on-device, built from `SPAGCore` only |
| `SPAGSchoolSync/` | Class joining, sync, token storage and content updates. Built into SPAG Buddy School only |
| `SPAG Buddy/` | SPAG Buddy School app, built from `SPAGCore` and `SPAGSchoolSync` |
| `SPAG BuddyTests/`, `SPAG Buddy HomeTests/` | Unit tests (Swift Testing) for School and Home |
| `Scripts/check-home-on-device.sh` | Build phase that fails the Home build if networking code reaches it |
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

## iOS app

Open `SPAG Buddy.xcodeproj` in Xcode 26 or later. There are two apps, which share code but never data:

- **SPAG Buddy Home** (`SPAG Buddy Home` scheme, bundle ID `Digital-Clubhouse.SPAG-Buddy-Home`) is for families. It is strictly on-device: no networking, no class features, no `spagbuddy://` links, content only from the app bundle, and no third-party SDKs. Its `PrivacyInfo.xcprivacy` declares no data collected and no tracking.
- **SPAG Buddy School** (`SPAG Buddy` scheme, bundle ID `Digital-Clubhouse.SPAG-Buddy`) adds `SPAGSchoolSync`: joining a class with a login card, sending answers to the teacher dashboard and downloading new content.

The Home target's first build phase runs `Scripts/check-home-on-device.sh`. It fails the build if `SPAGCore` or `SPAG Buddy Home` mention `URLSession`, `URLRequest`, `NWConnection`, `WKWebView`, `import Network`, any `http://` or `https://` address, school sync types, Keychain calls or a non-Apple import, or if the Home target gains `SPAGSchoolSync`, a Swift package, a URL type or tracking. The only web addresses allowed are the App Store review and privacy policy links in `SPAG Buddy Home/ExternalLinks.swift`, which open in Safari through SwiftUI `Link`. Run the script by hand with `Scripts/check-home-on-device.sh`. `HomeEditionTests` checks the same rules at run time.

- Minimum iOS version is 17.0 so older school iPads are supported.
- School only: set the API URL with the `SPAG_API_BASE_URL` build setting (for example `https://<project-ref>.supabase.co/functions/v1/api`). If it is empty the School app runs in offline-only mode.
- School only: pupil device tokens are stored in the Keychain. In both apps, practice data is stored locally with SwiftData and is not synced to iCloud.

Source layout inside `SPAGCore/`:

- `Models/` SwiftData models (`PupilProfile`, `Attempt`, `Assignment`, `BadgeProgress`) and content types (`Question`, `Objective`, `SpellingList`)
- `Services/` content loading, answer marking, session building, badges, speech, and the `ClassServices` protocol that only School implements
- `Views/` onboarding, home, practice, progress and settings screens
- `Theme/` colours, fonts and accessibility settings

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

Question banks live in `SPAGCore/Resources/Content/year1.json` to `year6.json`. Objectives are in `objectives.json` and spelling lists in `spelling-lists.json`. After changing content:

1. Run the unit tests (they validate every question).
2. Bump `contentVersion` in `manifest.json`.
3. Run `npm run seed` in `backend/` so the server and the website know about new questions.
4. Run `npm run upload-content` in `backend/` so iPads that are already installed download the new questions.

## Privacy

SPAG Buddy is designed for the UK GDPR and the ICO Age Appropriate Design Code (Children's Code). See [`docs/privacy/`](docs/privacy/). The school is the data controller. No pupil email addresses, photos, location, advertising or third-party analytics are used. Pupils can read what happens to their answers in the app. Before a school pilot, work through [`docs/pilot-checklist.md`](docs/pilot-checklist.md).
