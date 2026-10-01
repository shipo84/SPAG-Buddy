# ICO Children's Code: how SPAG Buddy meets the 15 standards

The [Age Appropriate Design Code](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/) applies to online services likely to be used by children. SPAG Buddy's users are 4 to 11, so the "ages 0 to 5" and "6 to 9" and "10 to 12" guidance all apply.

| # | Standard | How SPAG Buddy meets it | Where |
| --- | --- | --- | --- |
| 1 | Best interests of the child | The only purpose is helping children learn. No ads, purchases, social features or engagement tricks. Feedback is kind and explains the rule. | Plan; `FeedbackPanel.swift` |
| 2 | Data protection impact assessment | Pre-filled DPIA for schools. | [dpia.md](dpia.md) |
| 3 | Age appropriate application | Everything is designed for primary ages: big buttons, picture and PIN sign-in, read-aloud on every question and on the privacy notice. | `Views/`, `SpeechService.swift` |
| 4 | Transparency | "What happens to my answers?" in plain words for children, with a read-aloud button, on the welcome screen and in each pupil's settings. Separate notice for schools and parents. | `MyDataView.swift`, `PrivacyNotice.swift`, [pupil-privacy-notice.md](pupil-privacy-notice.md) |
| 5 | Detrimental use of data | Answers are used only to pick questions and inform the teacher. No leaderboards or comparisons between pupils. The SATs guide is teacher-only and labelled as indicative. | `SessionBuilder.swift`, web SATs page |
| 6 | Policies and community standards | The privacy notices and retention policy describe what really happens, and automated tests check the deletion rules. | [retention-policy.md](retention-policy.md), `backend/scripts/test-db.sql` |
| 7 | Default settings | High privacy by default: home profiles never leave the iPad, SwiftData has no iCloud sync, and nothing is sent until a teacher's class code is used. | `PupilStore.swift`, `Attempt.swift` (`needsSync`) |
| 8 | Data minimisation | First name, picture and answers only. No surnames, birthdays, emails, photos, audio or location. Names with digits or @ are rejected. | `validation.ts`, `web/lib/names.ts` |
| 9 | Data sharing | No sharing with anyone except the hosting sub-processor acting for the school. | [data-processing-agreement.md](data-processing-agreement.md) |
| 10 | Geolocation | Not collected. The app asks for no location permission. | `Info.plist` |
| 11 | Parental controls | Grown-up actions (removing a profile, sync details) sit behind a simple adult check. Accessibility settings are never locked. Children are not monitored without knowing: the notice says the teacher can see their answers. | `GrownUpGateView.swift`, `PupilSettingsView.swift` |
| 12 | Profiling | The only profiling is choosing practice questions from the child's own mastery, which is core to the service and explained in the notice ("helps Buddy choose the best questions for you"). No profiling for any other purpose. | `SessionBuilder.swift`, `Progress.swift` |
| 13 | Nudge techniques | No push notifications, no timers pressuring children, no rewards that lapse. Streaks simply restart after a missed day, with no penalty. Wrong answers use orange, not red. | `Progress.swift` (`StreakCalculator`), `Theme.swift` |
| 14 | Connected toys and devices | Not applicable. | |
| 15 | Online tools | Children can read what is kept in the app. Teachers can export, correct or delete a pupil's data at any time, and a grown-up can delete a home profile on the iPad. | Teacher website, `GrownUpSettingsView.swift` |

## Review

Review this table before each release that changes what is collected, who can see it, or how children are rewarded.
