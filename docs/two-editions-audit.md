# Two editions audit: SPAG Buddy Home and SPAG Buddy School

Status: audit only. No code has been changed. Branch `two-editions`, cut from `cursor/spag-buddy-uk-mvp-a6d4`.

Update: the Home split is now in place (`SPAGCore/`, `SPAGSchoolSync/`, `SPAG Buddy Home/`, see the README). It follows section 3's `ClassServices` proposal and Option A (one shared schema) for the models. `TeacherGateView` was renamed `GrownUpGateView`.

Goal: one codebase that builds two App Store apps.

- **SPAG Buddy Home** (parents): strictly on-device, with no networking code compiled in.
- **SPAG Buddy School** (classes): pupils join with a login card (QR code, or class code plus picture plus PIN) and answers sync to the teacher dashboard API.

The two editions share **source code and bundled content only**. They are two completely separate apps, and no pupil data, settings, tokens or links ever pass between them. Section 0 sets out what that means in practice.

## 0. The two apps are completely separate

Home and School are built from the same code, but on a device they are unrelated apps. Nothing one app stores can be read by the other, and neither app can open, detect or hand data to the other. This is a hard requirement for every later step.

### What is shared, and what is never shared

| Shared (at build time only) | Never shared (at run time) |
| --- | --- |
| Swift source for quizzes, marking, progress and UI | Pupil profiles, answers, stars, streaks and stickers |
| Bundled question banks, spelling lists and avatars (`Resources/Content`) | Class membership, assignments and device tokens |
| Theme and components, with per-edition branding | Settings, including `UserDefaults` such as `activePupilID` |
| Unit tests for the shared logic | Keychain items, files in Application Support, the SwiftData store |

Sharing a Swift type such as `PupilProfile` is a code decision. It does not connect the two apps' data: each app has its own copy of the code and its own store in its own sandbox.

### How the separation is guaranteed

iOS already keeps each app's data in its own sandbox. The apps stay separate as long as **none** of the following is ever added to either edition:

1. **The same bundle ID.** Each edition gets its own bundle ID and its own App Store Connect record (for example `Digital-Clubhouse.SPAG-Buddy-Home` and `Digital-Clubhouse.SPAG-Buddy-School`). Both apps can be on the same device at once and do not know about each other.
2. **App Groups.** No `com.apple.security.application-groups` entitlement and no `UserDefaults(suiteName:)` or `containerURL(forSecurityApplicationGroupIdentifier:)`. This is the only normal way for two apps from one developer team to share files or settings. Both apps will be signed by the same team (`KP535DY4P7`), which on its own shares nothing.
3. **Shared keychain access groups.** No `keychain-access-groups` entitlement. Home has no keychain code at all. School keeps its tokens in its own default access group.
4. **iCloud.** No CloudKit, no iCloud Documents and no `NSUbiquitousKeyValueStore` in either app. SwiftData is already set to `cloudKitDatabase: .none`, and that must stay.
5. **A shared or overlapping URL scheme.** Only School registers `spagbuddy://`. Home registers **no** URL scheme. If both apps claimed `spagbuddy`, iOS would pick one unpredictably, and a pupil scanning a class login card could end up in the Home app. Neither app opens the other with `openURL` or `canOpenURL`.
6. **Universal links or associated domains** pointing at either app.
7. **Any hand-over between the apps.** No import or export of progress, no shared files (`UIFileSharingEnabled`, document types), no pasteboard tricks, no share extensions that pass pupil data, and no "move this child to School" or "take my class work home" feature.
8. **A shared server identity.** Home never talks to the backend, so it has no pupil ID, device token or class link. A child's School account and any Home profile on the same iPad are unrelated records.

### What this means for families and schools

- A child who uses both apps has two independent profiles. Home progress does not appear in School or on the teacher dashboard, and School work and assignments do not appear in Home.
- Moving from one app to the other means starting again. There is no migration path, by design.
- Each app has its own App Store privacy label and privacy policy. Home can declare "Data Not Collected". School keeps the school documents in `docs/privacy/`.
- Deleting one app deletes only that app's data.

### Where today's single app crosses this line

Today there is one app that does both jobs, so it mixes home and class pupils in **one** store, on one picker screen, under one bundle ID. Specifically:

- `WelcomeView` offers "Join my class" and "Practise at home" side by side, and `PupilPickerView` lists both kinds of pupil together.
- `PupilProfile.isInClass` decides at run time whether a pupil's answers are uploaded. In the two-app design, that decision is made by which app is installed, not by a field.
- `PrivacyNotice.sections(inClass: nil)` explains both options in one notice.
- The existing bundle ID `Digital-Clubhouse.SPAG-Buddy`, which carries the `spagbuddy` scheme, has to go to one edition only (or be retired). It must not be shared.

These are the places the split has to cut. Section 5 lists them line by line.

## Summary

- The app has a single target, `SPAG Buddy`, with 47 Swift files in total: 38 in the app, 7 in the unit tests and 2 in the UI tests. It uses Xcode 16 file-system synchronised folders, so every file in `SPAG Buddy/` is compiled into the app automatically. The only membership exception is `Info.plist`.
- The networking code is already fairly contained. Only `APIClient.swift` touches `URLSession`/`URLRequest`, and only `SyncService.swift` imports `Network`. The rest of the network code (`ContentUpdater`, `KeychainStore`, `JoinClassView` and the parts of `APIModels.swift` the school edition needs) only runs when `APIClient.live` is not `nil`.
- The work is in the **seams**, not in moving files. `AppModel` owns a non-optional `SyncService` and calls `ContentUpdater` and `APIClient` directly. Seven shared views and files call `app.sync`, `JoinClassView`, `KeychainStore` or `ContentUpdater`. All of them have to be cut before the shared core can compile without the school files (see section 5).
- The pupil data schema (`PupilProfile`, `Attempt`, `Assignment`) holds class fields such as `remotePupilId`, `needsSync` and the whole `Assignment` model. Because Home must not hold class data in any form, I now recommend that Home's models leave these fields out, rather than one shared schema (details and the trade-off in section 5). Either way, each app keeps its own separate store.
- `TeacherGateView` is **not** school-only. Despite the name, it is the generic "Grown-ups only" multiplication puzzle that `HomeView` uses in front of `GrownUpSettingsView`. The Home edition needs it too.
- The real deployment target is **iOS 17.0** (`IPHONEOS_DEPLOYMENT_TARGET`, set at project level), not iOS 26.2. The SwiftUI and SwiftData APIs in use are fine on 17. Raise the target on purpose if 26.2 is what you want.

---

## 1. Swift files by group

Line counts are in brackets.

### 1a. Shared core: content, quizzes, progress, UI

These have no school or network dependency and can go into both editions unchanged.

| File | Role |
| --- | --- |
| `SPAG Buddy/Models/Content.swift` (192) | Objective, Question, SpellingList, Avatar, Strand and manifest types |
| `SPAG Buddy/Models/BadgeProgress.swift` (17) | SwiftData model for stickers |
| `SPAG Buddy/Services/ContentLibrary.swift` (154) | Loads and validates the bundled JSON content, and builds the spelling questions |
| `SPAG Buddy/Services/AnswerMarker.swift` (78) | Marks answers |
| `SPAG Buddy/Services/SessionBuilder.swift` (152) | `SessionMode` and question selection. It includes `.assignment(...)`, but that is pure local logic |
| `SPAG Buddy/Services/Progress.swift` (161) | Streaks, objective stats, badges, `Calendar.ukCalendar` |
| `SPAG Buddy/Services/SpeechService.swift` (28) | `AVSpeechSynthesizer` with an en-GB voice, on-device |
| `SPAG Buddy/Theme/Theme.swift` (112) | `AppTheme`, colours, easy-read and high-contrast settings |
| `SPAG Buddy/Views/Components/BuddyView.swift` (112) | Mascot |
| `SPAG Buddy/Views/Components/Components.swift` (192) | Buttons, cards, `PinPad`, `AvatarGrid`, `BuddySays` and similar |
| `SPAG Buddy/Views/Onboarding/CreateProfileView.swift` (86) | Local profile creation ("Practise at home"). No school code, but it is Home's onboarding only. School pupils only come from the join flow (see section 5) |
| `SPAG Buddy/Views/Onboarding/PupilPickerView.swift` (54) | "Who is practising?" |
| `SPAG Buddy/Views/Practice/AnswerInputView.swift` (234) | Answer input UI |
| `SPAG Buddy/Views/Practice/FeedbackPanel.swift` (75) | Feedback UI |
| `SPAG Buddy/Views/Practice/PracticeSession.swift` (136) | Session state machine. It sets `assignment.completedAt` locally, which is harmless in Home |
| `SPAG Buddy/Views/Practice/SessionSummaryView.swift` (91) | End-of-session screen |
| `SPAG Buddy/Views/Progress/PupilProgressView.swift` (121) | Progress screen |
| `SPAG Buddy/Views/Settings/PupilSettingsView.swift` (53) | Accessibility settings. It passes `pupil.isInClass` to `MyDataView` |
| `SPAG Buddy/Views/Settings/MyDataView.swift` (62) | Privacy notice screen. Its wording comes from `PrivacyNotice` |
| `SPAG Buddy/Views/Settings/TeacherGateView.swift` (64) | Grown-ups puzzle gate. See the note in section 1c |
| Tests: `AnswerMarkerTests`, `ContentTests`, `ProgressTests`, `SessionBuilderTests`, `TestContent` | Test shared logic only |
| UI tests: `SPAG_BuddyUITests`, `SPAG_BuddyUITestsLaunchTests` | Xcode template launch tests |

### 1b. School-only

These can be excluded from the Home target completely.

| File | Why |
| --- | --- |
| `SPAG Buddy/Services/APIClient.swift` (80) | `URLSession`, `URLRequest`, reads `SPAGBuddyAPIBaseURL`, and has join, upload, assignments, content manifest and download calls |
| `SPAG Buddy/Services/SyncService.swift` (138) | Upload and assignment sync, `NWPathMonitor` (`import Network`), the foreground observer, and the `Attempt.upload` extension |
| `SPAG Buddy/Services/ContentUpdater.swift` (44) | Remote content download, plus loading previously downloaded content from Application Support |
| `SPAG Buddy/Services/KeychainStore.swift` (47) | Stores the per-pupil device token (service `Digital-Clubhouse.SPAG-Buddy.device-token`) |
| `SPAG Buddy/Views/Onboarding/JoinClassView.swift` (167) | Class code, picture and PIN join flow. Calls `APIClient.live.join`, then `KeychainStore.saveToken` |
| `SPAG BuddyTests/SyncTests.swift` (82) | Tests `SyncPlanner`, `AttemptUpload`, `AssignmentsResponse`, `APIError` and `ContentVersion` |

The `spagbuddy://` URL scheme is also school-only. It is spread across `Info.plist` (`CFBundleURLTypes`), `SPAG_BuddyApp.swift` (`.onOpenURL`), `AppModel.handle(url:)` and `JoinDetails`, and `RootView` (`.sheet(item: $app.pendingJoin)`).

### 1c. Unclear or mixed: shared files with school code inside

These files belong in both editions, but each one has school hooks that must be split out or put behind a protocol. Section 5 lists every line.

| File | What is mixed in |
| --- | --- |
| `SPAG Buddy/SPAG_BuddyApp.swift` (61) | `.onOpenURL`, `ContentUpdater.loadDownloadedContent`, and a schema that includes `Assignment` |
| `SPAG Buddy/Services/AppModel.swift` (51) | Owns `let sync: SyncService`, takes `api: APIClient?`, its `start()` runs sync and the content update, and it has `handle(url:)`, `pendingJoin` and `JoinDetails` |
| `SPAG Buddy/Services/APIModels.swift` (154) | Mostly school DTOs (`JoinRequest/Response`, `AttemptUpload`, `AttemptBatch`, `AttemptUploadResponse`, `AssignmentDTO`, `AssignmentsResponse`, `RemoteContentManifest`, `APIErrorBody`, `APIError`, `SyncPlanner`, `JSONEncoder/Decoder.api`). It also contains `ContentVersion`, which is a generic version comparer. All of it is plain Foundation with no networking, but none of it is needed in Home. I recommend making the whole file school-only and moving `ContentVersion` to `ContentUpdater.swift`, since `ContentUpdater` is its only app-side user |
| `SPAG Buddy/Services/Previews.swift` (31) | `AppModel(..., api: nil)` |
| `SPAG Buddy/Services/PrivacyNotice.swift` (78) | Has three wording variants: `nil` (not chosen yet, which mentions joining a class), `true` (in a class) and `false` (home). Home only needs the `false` wording, and its "before choosing" wording must not mention a school. School probably only needs `true` |
| `SPAG Buddy/Models/PupilProfile.swift` (78) | Class fields (`remotePupilId`, `classCode`, `className`, `lastSyncedAt`), the `assignments` relationship and `isInClass` |
| `SPAG Buddy/Models/Attempt.swift` (62) | `needsSync` (set from `pupil.isInClass`) and `assignmentId` |
| `SPAG Buddy/Models/Assignment.swift` (36) | A SwiftData model for teacher-set work. Only `SyncService` creates it, but `HomeView` and `PracticeSession` read it |
| `SPAG Buddy/Views/RootView.swift` (38) | Join sheet driven by `pendingJoin`, and `.task { await app.start() }` |
| `SPAG Buddy/Views/Onboarding/WelcomeView.swift` (73) | "Join my class" button opening `JoinClassView`, plus card and PIN wording. This is where the two onboardings split |
| `SPAG Buddy/Views/Home/HomeView.swift` (233) | `app.sync.syncNow` in `.refreshable` and `.task`, the "From your teacher" assignments section, and `className` in the header |
| `SPAG Buddy/Views/Practice/PracticeSessionView.swift` (190) | `close()` calls `app.sync.syncNow` |
| `SPAG Buddy/Views/Settings/GrownUpSettingsView.swift` (94) | The class section (`app.sync.lastError`, `syncNow`, the unsynced count) and `KeychainStore.deleteToken` in `remove()` |
| `SPAG Buddy/Views/Settings/TeacherGateView.swift` (64) | Listed as school-only in the brief, but it has **no** school code. It is the grown-ups puzzle gate that both editions need. I suggest renaming it to `GrownUpGateView` in a later step |
| `SPAG BuddyTests/PrivacyNoticeTests.swift` (41) | Runs through all three `inClass` variants. Needs updating if the variants change per edition |

---

## 2. Every place that touches the network

### 2a. HTTP and sockets

| Location | What |
| --- | --- |
| `APIClient.swift:2-4` | `#if canImport(FoundationNetworking) import FoundationNetworking` (for Linux only, no effect on iOS) |
| `APIClient.swift:9` | `var session: URLSession = .shared` |
| `APIClient.swift:12-17` | `APIClient.live` reads `SPAGBuddyAPIBaseURL` from Info.plist. It only accepts `https` URLs or `localhost` |
| `APIClient.swift:19-34` | `POST pupil/join`, `POST attempts`, `GET assignments`, `GET content/manifest` |
| `APIClient.swift:36-40` | `download(_ url:)`, a `URLRequest` to any URL taken from the content manifest |
| `APIClient.swift:52-60` | Builds a `URLRequest` with a `Bearer` token header and a JSON body |
| `APIClient.swift:73` | `session.data(for:)`, the only actual network call in the app |
| `SyncService.swift:2, 19, 34-38` | `import Network`, `NWPathMonitor` (watches for connectivity, makes no network calls itself) |
| `SyncService.swift:73, 80` | `api.uploadAttempts`, `api.assignments` |
| `ContentUpdater.swift:21, 32` | `api.contentManifest()`, `api.download(file.url)` |
| `JoinClassView.swift:27, 129, 135` | `APIClient.live == nil` check, then `api.join(...)` |
| `AppModel.swift:21` | Default argument `api: APIClient? = APIClient.live` |
| `AppModel.swift:30-31` | `APIClient.live` and `ContentUpdater.update(using:)` |

### 2b. Hard-coded http(s) strings

There are none in the Swift code. The only `http://` strings are the DOCTYPE lines in `Info.plist` and `SPAG_Buddy.entitlements`. The base URL comes from the `SPAG_API_BASE_URL` build setting, which is currently an empty string in both Debug and Release. That means `APIClient.live` is `nil` in every build today, and `JoinClassView` shows "Joining a class is not set up on this iPad yet."

### 2c. URL scheme handling

| Location | What |
| --- | --- |
| `Info.plist:9-19` | `CFBundleURLTypes`: name `Digital-Clubhouse.SPAG-Buddy.join`, scheme `spagbuddy` |
| `SPAG_BuddyApp.swift:23` | `.onOpenURL { appModel.handle(url: $0) }` |
| `AppModel.swift:36-42` | Parses `spagbuddy://join?class=…&picture=…&pin=…` with `URLComponents` and sets `pendingJoin` |
| `RootView.swift:26-30` | Shows `JoinClassView(prefilled:)`, which joins straight away |
| Outside the app | `backend/supabase/functions/_shared/codes.ts:54` and `web/lib/codes.gen.ts:55` generate the QR link. Nothing in the iOS app scans QR codes: the pupil uses the Camera app, which opens the scheme |

There are no `Link(...)`, `openURL` environment, universal links or associated domains anywhere in the app.

### 2d. Remote content download

| Location | What |
| --- | --- |
| `ContentUpdater.update(using:currentVersion:)` | Downloads the manifest and files, checks them in a temporary folder, then installs them to `Application Support/Content` |
| `ContentUpdater.loadDownloadedContent(newerThan:)` | Called at launch from `SPAG_BuddyApp.loadContent()` (line 59). It reads only from disk, but it reads content that was downloaded, so it belongs to the school edition |

### 2e. Things that look like networking but are not

- `SpeechService` uses on-device `AVSpeechSynthesizer` voices. Any enhanced voice downloads are handled by iOS, not by the app.
- `ContentLibrary.load(from:)` and `loadBundled` use `file://` URLs and `Data(contentsOf:)` only.
- `TestContent.directory` resolves files with `#filePath`.

---

## 3. Where AppModel, SyncService and ContentUpdater are created and started

### Current lifecycle

1. **`AppModel` is created** at `SPAG_BuddyApp.swift:17`: `@State private var appModel = AppModel(content: Self.loadContent(), container: Self.modelContainer)`. It is passed to the views with `.environment(appModel)` (line 22).
   - `Self.loadContent()` (lines 52-60) loads the bundled content, then replaces it with `ContentUpdater.loadDownloadedContent(...)` if the downloaded copy is newer. This is the **first ContentUpdater touch point**, and it runs synchronously at launch.
   - The preview `AppModel` is created at `Previews.swift:25` with `api: nil`.
2. **`SyncService` is created** inside `AppModel.init` (`AppModel.swift:23`): `sync = SyncService(api: api, container: container)`. `api` defaults to `APIClient.live`.
3. **Startup is triggered** at `RootView.swift:36` (`.task { await app.start() }`). `AppModel.start()` (`AppModel.swift:27-34`) then:
   - calls `sync.start()`. This returns early if `api == nil`; otherwise it starts the `NWPathMonitor` and the foreground observer, each of which calls `syncAll()`;
   - awaits `sync.syncAll()`;
   - calls `ContentUpdater.update(using:)` when `APIClient.live` is not `nil`, and swaps in the new `content` if it succeeds. This is the **second ContentUpdater touch point**.
4. **Other sync triggers** reach `app.sync` directly:
   - `HomeView.swift:45` (`.refreshable`)
   - `HomeView.swift:61` (`.task`)
   - `PracticeSessionView.swift:134` (`close()`)
   - `GrownUpSettingsView.swift:37, 43` (`lastError`, `syncNow`)

`ContentUpdater` is a static `enum`, so it is never created; it is only called.

### How to make them optional (proposal for review)

Today the app is "offline-capable" at runtime, because a `nil` `APIClient` turns sync off. But all the code is still compiled in. To keep it out of Home completely, the sync and content-update code has to leave the shared core and be reached through a small interface that Home does not provide.

1. **A protocol in the shared core.** Add one protocol, for example `ClassServices`, that covers only what the shared views need:
   - `start()`
   - `syncNow(pupil:)`
   - `lastError`
   - `forget(pupil:)` (replaces `KeychainStore.deleteToken`)
   - optionally `refreshContent(current:) async -> ContentLibrary?` and `launchContent(bundled:) -> ContentLibrary`
2. **`AppModel` holds an optional implementation.** Replace `let sync: SyncService` and the `api:` parameter with `let classServices: (any ClassServices)?`. Then `start()` becomes `await classServices?.start()`, and the views call `app.classServices?.syncNow(pupil:)` or hide their class UI when it is `nil`. The init then takes no `APIClient`, and `Previews.swift` simply passes `nil`.
3. **Each app entry point chooses.** Either give each edition its own `@main` file (`HomeApp.swift`, `SchoolApp.swift`), or keep one `@main` that calls an `Edition.makeServices(container:)` factory, which exists once per target. The School version builds `SchoolClassServices` (wrapping `SyncService`, `APIClient`, `ContentUpdater` and `KeychainStore`). The Home version returns `nil`, and its content loader skips `ContentUpdater`.
4. **Joining and URL handling move to the School entry point.** `.onOpenURL`, `pendingJoin` and `JoinDetails`, and the join sheet would be attached by the School app (for example, a `SchoolRoot` view that wraps the shared `RootView`). The shared `RootView` and `WelcomeView` then take the edition's onboarding as a parameter or an environment value, instead of naming `JoinClassView` directly.
5. **How to enforce it.** There are two options, and they can be combined.
   - **Separate folders and targets (preferred).** For example `Shared/`, `Home/` and `School/`, each added as a synchronised root group only to the targets that should compile it. The Home target simply cannot see `APIClient`, so any leak is a compile error.
   - **A compilation flag.** Set `SCHOOL_EDITION` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS` on the School target and wrap the remaining call sites in `#if SCHOOL_EDITION`. This is quicker, but the files still need excluding with per-target `membershipExceptions`, otherwise they compile into Home anyway.

---

## 4. Current bundle ID, display name, Info.plist keys, URL types and entitlements

### Targets

| Target | Bundle ID | Product |
| --- | --- | --- |
| `SPAG Buddy` (app) | `Digital-Clubhouse.SPAG-Buddy` | `SPAG Buddy.app` |
| `SPAG BuddyTests` | `Digital-Clubhouse.SPAG-BuddyTests` | unit tests (Swift Testing) |
| `SPAG BuddyUITests` | `Digital-Clubhouse.SPAG-BuddyUITests` | UI tests (XCTest) |

### App target build settings (Debug and Release are identical)

- `PRODUCT_NAME = $(TARGET_NAME)`, which gives "SPAG Buddy".
- **There is no display name.** `CFBundleDisplayName` / `INFOPLIST_KEY_CFBundleDisplayName` is not set, so the home-screen name is "SPAG Buddy", taken from the product name.
- `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`.
- `DEVELOPMENT_TEAM = KP535DY4P7`, `CODE_SIGN_STYLE = Automatic`.
- `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, inherited from the project. `TARGETED_DEVICE_FAMILY = 1,2` (iPhone and iPad).
- `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`.
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`. There is one icon set and one accent colour, so both editions would currently share the same branding.
- `GENERATE_INFOPLIST_FILE = YES` together with `INFOPLIST_FILE = SPAG Buddy/Info.plist`. The file is merged with the generated keys.
- `SPAG_API_BASE_URL = ""`, a custom setting that is substituted into Info.plist.
- `CODE_SIGN_ENTITLEMENTS = SPAG Buddy/SPAG_Buddy.entitlements`.

### Info.plist (`SPAG Buddy/Info.plist`)

| Key | Value |
| --- | --- |
| `CFBundleDevelopmentRegion` | `en-GB` |
| `SPAGBuddyAPIBaseURL` | `$(SPAG_API_BASE_URL)` (currently empty) |
| `CFBundleURLTypes` | One entry: `CFBundleURLName = Digital-Clubhouse.SPAG-Buddy.join`, `CFBundleURLSchemes = [spagbuddy]` |

Generated keys (from `INFOPLIST_KEY_*`):

- `UIApplicationSceneManifest_Generation = YES`
- `UIApplicationSupportsIndirectInputEvents = YES`
- `UILaunchScreen_Generation = YES`
- `UISupportedInterfaceOrientations_iPad`: all four orientations
- `UISupportedInterfaceOrientations_iPhone`: portrait, landscape left and landscape right

The plist has no `NSAppTransportSecurity`, no privacy usage strings (no camera, microphone or similar) and no `LSApplicationQueriesSchemes`.

### Entitlements (`SPAG Buddy/SPAG_Buddy.entitlements`)

The file is an empty `<dict/>`. There are no app groups, keychain access groups, associated domains or iCloud entitlements. The keychain uses the default access group, and SwiftData is explicitly set to `cloudKitDatabase: .none`.

### Other things to know for two App Store apps

- **No shared schemes are committed.** There is no `xcshareddata/xcschemes`, so CI and other machines rely on Xcode generating schemes automatically. Two editions will need two committed schemes.
- **Strings tied to the bundle ID** are all school-only. They go into the School app with the School bundle ID, and none of them appear in Home:
  - `KeychainStore` service `Digital-Clubhouse.SPAG-Buddy.device-token`
  - URL type name `Digital-Clubhouse.SPAG-Buddy.join`
  - `SyncService`'s dispatch queue label `spag-buddy.network`
- **Settings keys:** `UserDefaults` key `activePupilID`. Each app has its own sandbox, so the two copies of this key never meet. This is fine as long as neither app uses an App Group suite (see section 0).
- **The existing bundle ID:** `Digital-Clubhouse.SPAG-Buddy` goes to **one** edition, or is retired. It must not be used by both. If it has already been used on App Store Connect, the edition that keeps it inherits that record, and any test installs keep their old data. The other edition must start with a new bundle ID and an empty store.

---

## 5. What would stop the shared core compiling without the school files

This assumes the school files are excluded: `APIClient.swift`, `SyncService.swift`, `ContentUpdater.swift`, `KeychainStore.swift` and `JoinClassView.swift`, plus `APIModels.swift`, which is school-only once `ContentVersion` has moved out.

### Hard compile errors

| # | File:line | Code | Missing symbol |
| --- | --- | --- | --- |
| 1 | `SPAG_BuddyApp.swift:59` | `ContentUpdater.loadDownloadedContent(...)` | `ContentUpdater` |
| 2 | `AppModel.swift:12` | `let sync: SyncService` | `SyncService` |
| 3 | `AppModel.swift:21` | `api: APIClient? = APIClient.live` | `APIClient` |
| 4 | `AppModel.swift:23` | `SyncService(api:container:)` | `SyncService` |
| 5 | `AppModel.swift:28-33` | `sync.start()`, `sync.syncAll()`, `APIClient.live`, `ContentUpdater.update` | all three |
| 6 | `Previews.swift:25` | `AppModel(..., api: nil)` | the `api:` label, once item 3 is removed |
| 7 | `RootView.swift:28` | `JoinClassView(prefilled:)` | `JoinClassView` |
| 8 | `WelcomeView.swift:28` | `JoinClassView()` | `JoinClassView` |
| 9 | `HomeView.swift:45, 61` | `app.sync.syncNow(pupil:)` | `AppModel.sync` |
| 10 | `PracticeSessionView.swift:134` | `app.sync.syncNow(pupil:)` | `AppModel.sync` |
| 11 | `GrownUpSettingsView.swift:37, 43` | `app.sync.lastError`, `app.sync.syncNow` | `AppModel.sync` |
| 12 | `GrownUpSettingsView.swift:88` | `KeychainStore.deleteToken(for:)` | `KeychainStore` |
| 13 | `SPAG BuddyTests/SyncTests.swift` (whole file) | `SyncPlanner`, `AttemptUpload`, `APIError`, `ContentVersion`, `JSONDecoder.api` and more | School-only types. Move it to a School test target |

`AppModel.handle(url:)` and `JoinDetails` (`AppModel.swift:36-51`) would still compile, because they only use `URLComponents`. But they are scheme handling, and they should move to the School edition together with `.onOpenURL` (`SPAG_BuddyApp.swift:23`) and the `pendingJoin` sheet (`RootView.swift:26-30`).

### Would compile, but is dead or misleading in Home

These are not compile blockers, but they need a decision.

- **The schema and models.** `Assignment` is in `SPAG_BuddyApp.schema`, `PupilProfile` has class fields (`remotePupilId`, `classCode`, `className`, `lastSyncedAt`) and the `assignments` relationship, and `Attempt` has `needsSync` and `assignmentId`. These compile in Home, but they mean the Home app could represent class data. Two options:
  - **Option A: one shared schema.** Keep the models unchanged in both apps. This is the least work, and the data is still separate, because each app has its own store. But Home would carry empty class fields and an unused `Assignment` table.
  - **Option B: no class data in Home (recommended).** Home's models have no class fields and no `Assignment` model. The class fields and `Assignment` live only in School. This matches the requirement that Home cannot hold or receive school data in any form, and makes it checkable: if Home code mentions a class field, it does not compile. The cost is that the shared views must stop reading those fields directly, and get "is this a class pupil / what assignments are there" from the edition, so Home answers "no" and "none". It also means two schemas and separate tests for each.

  Neither option involves migrating data between the apps. Each app starts with its own empty store.
- **`SessionMode.assignment`** (`SessionBuilder.swift`) and the code in `PracticeSession.swift:90-93` that completes an assignment. With Option B, these move to School, because Home has no assignments.
- **Class UI that Home must not include**:
  - the "From your teacher" section in `HomeView`;
  - `pupil.className ?? "Year …"` in the `HomeView` header;
  - the class section and class wording in `GrownUpSettingsView`.

  These should be removed from Home, not just hidden behind `isInClass`. The class section of `GrownUpSettingsView` and the assignments section of `HomeView` can become School-only views that the School app injects.
- **Home pupils in School.** School should not offer "Practise at home" profiles either. Every School pupil is a class pupil who joined with a login card, so `CreateProfileView` is Home-only in practice, and School's onboarding is only the join flow.
- **Wording**:
  - `WelcomeView` has the "Join my class" button and "Your teacher will give you a card with your class code and PIN."
  - `PrivacyNotice.sections(inClass: nil)` says answers are sent to school if you join a class.
  - `GrownUpSettingsView` footers mention the teacher.

  Home must not say any of this, both for the App Store privacy label ("Data Not Collected") and for the Children's Code documents under `docs/privacy/`. `PrivacyNoticeTests` will need updating whenever the wording variants change.
- **The `ContentVersion` move.** If `APIModels.swift` becomes school-only, `ContentVersion` has to move first, or go with `ContentUpdater` into School. Nothing in the shared app code uses it. Only `ContentUpdater` and `SyncTests` do.

### Project-level blockers

These are not Swift errors, but they stop a clean split.

- All files in `SPAG Buddy/` are compiled into the single target automatically, because it is a file-system synchronised root group. Splitting means either per-target `membershipExceptions` or reorganising into `Shared/`, `Home/` and `School/` folders mapped to each target.
- One `Info.plist` carries both `CFBundleURLTypes` (school-only) and `SPAGBuddyAPIBaseURL`. Home needs its own plist (or a per-target `INFOPLIST_FILE`) without both.
- One entitlements file, one `AppIcon` and one `AccentColor` are shared. The entitlements file is empty, so that part is fine, but branding needs per-edition asset catalogues or icon names.
- The unit test target uses `@testable import SPAG_Buddy`. That module name comes from the product name, so renaming targets or products changes the import in every test file. Two app targets also mean the tests need a host (probably Home for the shared tests, and School for `SyncTests`).

---

## Not changed in this step

Nothing in the Swift code, project file, plist or entitlements has been touched. The untracked `docs/brand/` folder that was already in the working tree has been left out of this commit.
