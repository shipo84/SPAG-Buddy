# Pilot checklist: one Year 4 class

The plan is to pilot SPAG Buddy with one Year 4 class for half a term before offering it more widely.

## Before the pilot

### Legal and privacy

- [ ] School DPO has reviewed the [DPIA](privacy/dpia.md) and signed it off.
- [ ] [Data processing agreement](privacy/data-processing-agreement.md) is signed by the school and the operator.
- [ ] Operator details, contact email and hosting region are filled in on the [school privacy notice](privacy/school-privacy-notice.md).
- [ ] Letter to parents sent: what SPAG Buddy is, what is collected, and who to ask about it.
- [ ] Supabase DPA accepted in the Supabase dashboard; transfer mechanism checked.

### Backend

- [ ] Supabase project created in the London (eu-west-2) region.
- [ ] `supabase db push` applied the migration; `supabase/seed.sql` loaded; `npm run upload-content` run.
- [ ] pg_cron is enabled and `spag-buddy-purge` appears in `cron.job`.
- [ ] `api` function deployed with `--no-verify-jwt`; `ALLOWED_ORIGINS` set to the website's address.
- [ ] Auth: email sign-in on, sign-up limited to the school's email domain if possible, redirect URL set to `https://<site>/auth/callback`.
- [ ] Point-in-time recovery or daily backups on.
- [ ] `npm run check`, `npm test` and `sudo -u postgres npm run test:db` pass in `backend/`.

### Website

- [ ] `.env.local` (or hosting environment) has the Supabase URL and anon key. `NEXT_PUBLIC_DEMO_MODE` is not `true`.
- [ ] Hosted in the UK or EU (for example Vercel with the London region, or the school's own hosting).
- [ ] `npm test` and `npm run build` pass in `web/`.
- [ ] The teacher signs in, completes their profile and creates the class.

### iPads

- [ ] `SPAG_API_BASE_URL` set in the Xcode build settings to `https://<ref>.supabase.co/functions/v1/api`.
- [ ] App built and tested on an iPad running iPadOS 17, and on the latest iPadOS.
- [ ] Installed via TestFlight or the school's MDM.
- [ ] VoiceOver, Dynamic Type at the largest size, Easy-read text and Strong colours checked on the main screens.
- [ ] UK English voice (for example "Daniel" or "Serena") downloaded in iPad Settings > Accessibility > Spoken Content.

### Classroom

- [ ] Pupils added by first name; login cards printed and cut out.
- [ ] Teacher has tried each question type on an iPad, including the tap-the-gap punctuation questions.
- [ ] The class has read "What happens to my answers?" together.
- [ ] A plan for pupils without an iPad at a given time (shared iPads work: several pupils can join on one iPad).

## During the pilot

- [ ] Week 1: every pupil has joined and completed a daily practice. Check the heat map is filling in.
- [ ] Week 2: teacher sets an assignment and checks the "Started" count.
- [ ] Weekly: check sync. On the grown-ups' settings screen "Waiting to send" should return to 0 once the iPad is online.
- [ ] Log any question that pupils found confusing or marked unfairly. Check the "Common wrong answers" list on each skill page for answers that should have been accepted.
- [ ] Note any accessibility problems.

## What to measure

| Question | How |
| --- | --- |
| Do pupils use it? | Pupils practising and questions answered per week, from the overview page |
| Is it at the right level? | Share of answers right; aim for 65% to 85% overall |
| Does the teacher act on it? | Assignments set; teacher interview |
| Is marking fair? | Wrong answers that were really right, from the skill pages |
| Do pupils like it? | Short pupil voice session: what they liked, what was hard |

## After the pilot

- [ ] Decide whether to continue, and with which classes.
- [ ] Fix confusing questions and publish a new content version (bump `contentVersion` in `manifest.json`, run `npm run seed` and `npm run upload-content`).
- [ ] If not continuing: delete the class from the website, confirm deletion in writing to the school, and remove the app from iPads.
- [ ] Update the DPIA with anything learned.
