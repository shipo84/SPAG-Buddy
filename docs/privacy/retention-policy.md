# Retention and deletion policy

Deletion is automatic where possible, so it does not depend on anyone remembering. The nightly job is `public.purge_expired_data()` in `backend/supabase/migrations/20260930000000_init.sql`, scheduled with pg_cron at 02:30 UTC. `backend/scripts/test-db.sql` checks that deleting a pupil removes their results, and that the purge deletes data just past each limit below while keeping data just inside it.

## Retention periods

| Data | Kept for | How it is deleted |
| --- | --- | --- |
| Pupil answers (`attempts`) | 24 months from when the answer was given | Nightly purge |
| Archived class, with its pupils, answers, assignments and device links | 12 months after the teacher archives it | Nightly purge; related rows are removed by `on delete cascade` |
| Pupil, with their answers and device links | Until the teacher deletes them, or the class is purged | Teacher deletes on the website (`DELETE /pupils/{id}`); immediate |
| Whole class | Until the teacher deletes or archives it | Teacher deletes in class settings (`DELETE /classes/{id}`); immediate |
| Device tokens | 30 days after being revoked, or 12 months after last use | Nightly purge |
| Audit log (who deleted or reset what) | 24 months | Nightly purge |
| Teacher account | Until the teacher or school asks for it to be closed | On request, by the operator (see below) |
| Database backups | Supabase point-in-time recovery window, [7] days | Rolled off automatically |

Deleted data may remain in backups until the backup window has passed. It is never restored except to recover from a disaster, and in that case deletions made since the backup are re-applied.

## On the iPad

- Answers are kept on the iPad for the pupil's own progress screen and stickers.
- Answers waiting to be sent are removed from the upload queue once the server has accepted them.
- "Remove pupil" in the grown-ups' settings deletes the pupil's profile, answers, stickers and device token from the iPad.
- If a teacher deletes a pupil or archives the class, the iPad's token stops working. The app then stops sending answers and asks the pupil to join again.
- Nothing is stored in iCloud. The SwiftData store is local only (`cloudKitDatabase: .none`).

## End of the school year

1. Teachers move a continuing class up a year in **Class settings** to keep its history.
2. Classes of pupils who are leaving should be **archived**. Pupils can no longer sign in or send answers, and the class is deleted 12 months later.
3. If a pupil leaves mid-year, the teacher deletes them from the **Pupils** tab.

## Requests from pupils or parents

- **Access:** the teacher downloads the class CSV for the relevant dates and filters it to the pupil.
- **Erasure:** the teacher deletes the pupil. This is permanent and immediate.
- **Closing a teacher account:** the school emails [operator privacy email]. The operator deletes the `auth.users` row, which removes the teacher and their class links. Classes the teacher shared with colleagues remain.
