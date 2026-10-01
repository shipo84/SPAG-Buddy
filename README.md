# SPAG Buddy Home

SPAG Buddy is a spelling, punctuation and grammar (SPAG) practice app for UK primary pupils in Year 1 to Year 6. It follows the National Curriculum for English (Appendix 1: Spelling, Appendix 2: Vocabulary, Grammar and Punctuation) and includes KS2 SATs GPS-style practice for Year 6.

There are two SPAG Buddy apps, built as two separate Xcode projects:

- **SPAG Buddy Home** (this project): for families. Strictly on-device. No account, no class, no sync, no server. Nothing a child does ever leaves the iPad.
- **SPAG Buddy School** (a separate project): for classes. Pupils join with a login card and answers sync to a teacher dashboard.

The two apps have different bundle IDs and share no data. A child who uses both has two unrelated profiles. See [`docs/two-editions-audit.md`](docs/two-editions-audit.md) for the reasoning and the rules that keep them separate.

## Repository layout

| Path | What it is |
| --- | --- |
| `SPAG Buddy Home.xcodeproj` | The Xcode project |
| `SPAG Buddy/` | iOS and iPadOS app (SwiftUI + SwiftData, iOS 17+) |
| `SPAG Buddy/Resources/Content/` | Curriculum objectives, question banks and statutory spelling lists (JSON). This is the single source of truth for content. |
| `SPAG BuddyTests/` | Unit tests (Swift Testing) |
| `backend/`, `web/` | The School edition's Supabase backend and teacher website. Not used by Home; they are here from before the two projects were split and belong with the School project. |
| `docs/` | Two-editions audit, privacy notices, DPA and DPIA templates, retention policy and pilot checklist |

## iOS app

Open `SPAG Buddy Home.xcodeproj` in Xcode 26 or later and run the **SPAG Buddy Home** scheme.

- Bundle ID `Digital-Clubhouse.SPAG-Buddy-Home`, display name "SPAG Buddy Home".
- Minimum iOS version is 17.0.
- There is no networking code in the app at all: no `URLSession`, no API client, no Keychain, no URL scheme. Content is loaded from the bundle only.
- Practice data is stored locally with SwiftData and is not synced to iCloud. The SwiftData schema is `PupilProfile`, `Attempt` and `BadgeProgress`; there are no class or assignment fields.

Source layout inside `SPAG Buddy/`:

- `AppInfo.swift` the app name and tagline
- `Models/` SwiftData models (`PupilProfile`, `Attempt`, `BadgeProgress`) and content types (`Question`, `Objective`, `SpellingList`)
- `Services/` content loading, answer marking, session building, badges, speech and the pupil privacy notice
- `Views/` onboarding, home, practice, progress and settings screens
- `Theme/` colours (Home is teal), fonts and accessibility settings

### Keeping Home and School in step

The question banks in `SPAG Buddy/Resources/Content/` and the shared Swift code (models, `Services/`, `Views/`, `Theme/`) are the same in both projects. When you fix a question or improve a screen in one project, copy the change to the other. The School project additionally has `APIClient`, `SyncService`, `ContentUpdater`, `KeychainStore`, `JoinClassView`, the `Assignment` model and the class fields on `PupilProfile` and `Attempt`.

## Backend and teacher website (School edition only)

`backend/` and `web/` belong to the School edition. Home never talks to them. See [`backend/README.md`](backend/README.md) and [`web/README.md`](web/README.md), plus [`docs/deploy-teacher-website.md`](docs/deploy-teacher-website.md) and [`docs/wordpress-without-supabase.md`](docs/wordpress-without-supabase.md).

## Content

Question banks live in `SPAG Buddy/Resources/Content/year1.json` to `year6.json`. Objectives are in `objectives.json` and spelling lists in `spelling-lists.json`. After changing content:

1. Run the unit tests (they validate every question).
2. Bump `contentVersion` in `manifest.json`.
3. Copy the same change into the School project, and there run `npm run seed` and `npm run upload-content` in `backend/` so the server and already-installed School iPads get the new questions.

## Privacy

SPAG Buddy Home is designed for the UK GDPR and the ICO Age Appropriate Design Code (Children's Code). It collects nothing: no account, no email address, no photos, no location, no advertising, no analytics, and no data leaves the device. Its App Store privacy label can be "Data Not Collected". Pupils can read what happens to their answers in the app. The school-facing documents in [`docs/privacy/`](docs/privacy/) and [`docs/pilot-checklist.md`](docs/pilot-checklist.md) apply to the School edition.
