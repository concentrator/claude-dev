---
task: R091-T003
type: mnt
mode: normal
---

- [x] After a merge the session writes a handoff of at most 10 lines to
  `.git/dev-handoff.md` (what merged, the next item by id, open MR/PRs,
  user decisions not yet in a file) and asks the user to `/clear`.
  Approach: `finish.md § 4` gains the step; `branch-plan.md § Session
  boundary` cites it in place of its re-brief list.
- [x] On a `clear` or `startup` start, `dev-session-brief.sh` injects the
  handoff with the tree state, then deletes the file; with no handoff it
  stays silent, and `compact|resume` starts keep today's brief. Approach:
  the hook, its test, the installer's matcher, README's hook table and
  passage.
- [x] Complete the branch: cleanup, mark plan complete, mark the task `[x]`
  in the R's `tasks.md`, commit.
