---
task: R091-T001
type: mnt
mode: normal
---

- [x] In normal mode any seat edits plan text while the requirements hold,
  with no planner dispatch, cold read or approval, and the session or the
  working implementer applies a small fix mid-branch, never a new seat.
  Approach: `branch-plan.md § Plan edits`, `§ Scope changes mid-branch`,
  `§ Rails`; `plan.md § Adjusting existing plans`; `run.md`; the planner
  and implementer definitions.
- [x] In normal mode the task report holds one line per entry - an item's,
  written once it is checked, an answer, a review finding - with no claims,
  evidence or skeleton; strict keeps today's report. Approach:
  `branch-plan.md § Body`, `§ Commit cadence`, `§ Task report`;
  `report-template.md`; the implementer.
- [x] Claims and Proven belong to strict plans; in normal mode the doc
  writer, docs verifier and code reviewer work from the diff and the plan
  items. Approach: `documentation.md § Claims`, those three seats,
  `verification-policy.md`.
- [x] `check-plan-text.sh` runs its claims, Proven, report-skeleton and
  `Evidence:` checks on strict plans only, and fails a normal plan's report
  entry over one line. Approach: the script, then its test.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included.

## Claims

- none

## Proven

- none
