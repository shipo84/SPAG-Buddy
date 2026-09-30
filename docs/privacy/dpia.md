# Data protection impact assessment: SPAG Buddy

*Pre-filled template for the school's DPO, following the ICO DPIA template. Children's data and new technology in schools usually justify a DPIA even where the risk is low. Replace the items in [square brackets] and review before the pilot.*

| | |
| --- | --- |
| School | [name, URN] |
| DPO | [name, contact] |
| Completed by | [name, role] |
| Date | [date] |
| Review date | [one year later, or before any change in how SPAG Buddy is used] |

## 1. Why a DPIA is needed

SPAG Buddy processes information about children, using an app and a cloud service. The ICO Children's Code expects a DPIA for online services likely to be used by children.

## 2. Description of the processing

**Nature.** Pupils answer spelling, punctuation and grammar questions on school iPads. Answers are stored on the iPad and sent to a hosted database when online. Teachers view class and pupil summaries on a website, set work, and can download answers as a spreadsheet.

**Scope.** Pupils in [number] classes, Years [x to y], about [number] pupils. Data per pupil: first name, avatar, hashed PIN, class, year group and practice answers. See section 3 of the [school privacy notice](school-privacy-notice.md). Retention: see the [retention policy](retention-policy.md).

**Context.** Pupils are aged 4 to 11 and use SPAG Buddy in lessons or supervised practice. Parents will reasonably expect the school to use learning software. There is no contact between pupils and no content from other users.

**Purposes.** Help pupils practise the curriculum at the right level; help teachers see what their class needs.

## 3. Consultation

- [Class teachers and the English lead: date and summary.]
- [Parents informed by letter or newsletter: date.]
- [Pupils: the child-friendly notice was read with the pilot class; any questions.]
- Processor: technical details in the [data processing agreement](data-processing-agreement.md).

## 4. Necessity and proportionality

- **Lawful basis:** public task (maintained schools and academies) or legitimate interests (independent schools).
- **Minimisation:** first name only. No surnames, dates of birth, UPNs, email addresses, photos, audio, location, SEN or characteristics data. The website rejects pupil names with digits or @.
- **Accuracy:** teachers can rename pupils. Answers are recorded as given.
- **Retention:** automatic deletion after 24 months (answers) and 12 months after a class is archived.
- **Rights:** access via CSV export; erasure by deleting the pupil; rectification by renaming.
- **Processor:** written agreement under Article 28, with sub-processors listed.
- **Transfers:** hosted in [UK/EU]. See section 6 of the DPA.

## 5. Risks

Likelihood and severity are rated remote, possible or probable, and minimal, significant or severe.

| # | Risk to pupils | Likelihood | Severity | Overall |
| --- | --- | --- | --- | --- |
| 1 | Unauthorised access to a class's results through a stolen teacher account | Remote | Minimal | Low |
| 2 | A pupil signs in as a classmate using a lost login card | Possible | Minimal | Low |
| 3 | Answers are seen by teachers at another school | Remote | Minimal | Low |
| 4 | Staff put extra personal data (surnames, SEN notes) into name fields | Possible | Significant | Medium |
| 5 | Data kept longer than needed after pupils leave | Possible | Minimal | Low |
| 6 | Pupils feel judged or pressured by scores | Possible | Significant | Medium |
| 7 | A spreadsheet export is shared or left on a shared computer | Possible | Minimal | Low |
| 8 | A breach at the hosting provider | Remote | Significant | Low |

## 6. Measures to reduce risk

| # | Measures | Residual risk |
| --- | --- | --- |
| 1 | Single-use email sign-in links, no passwords. Database row-level security limits each teacher to their own classes. Staff who leave are removed from classes. | Low |
| 2 | 4-digit PIN plus the right picture; sign-in locks after 5 wrong PINs. Cards show only a first name. Teachers can issue a new PIN at any time, which stops the old one working. | Low |
| 3 | Row-level security checks class membership on every query, and is tested automatically (`backend/scripts/test-db.sql`). | Low |
| 4 | Guidance on the "Add pupils" screen; names over 30 characters or with digits or @ are rejected. Staff briefing before the pilot. | Low |
| 5 | Archiving at the end of the year; automatic deletion 12 months later; answers deleted after 24 months regardless. | Low |
| 6 | No leaderboards or comparisons between pupils. Stars and stickers reward effort and streaks. Wrong answers get gentle feedback in orange, not red. The Year 6 SATs guide is shown only to teachers and states that it is not a scaled score. | Low |
| 7 | Exports contain first names only, and use the minimum date range the teacher chooses. School policy on storing exports: [policy]. | Low |
| 8 | Encryption in transit and at rest; minimal data held; hashed PINs and tokens; breach notification within 24 hours under the DPA. | Low |

## 7. Sign-off

| Item | Name and date | Notes |
| --- | --- | --- |
| Measures approved by | | |
| Residual risks approved by | | If any risk is high, consult the ICO before starting |
| DPO advice | | |
| DPO advice accepted or overruled by | | If overruled, give reasons |
| Consultation responses reviewed by | | |
| DPIA to be kept under review by | | |
