---
task: R089-T006
type: mnt
depends-on: R089-T008
mode: normal
---

- [ ] A close fix whose `## Review` entry meets `verification-policy.md
  § Mechanical commits`, read from the entry's text, costs no seat: the runner
  applies it and commits it, fast tier green, with the entry's `[x]`; a red tier
  reverts it to a fresh implementer, as other entries go (requirement outcome
  8). Approach: `run.md` § Close 2, § Batch close 2, § Seats, § Monitor,
  that section, then `branch-plan.md` § Task report, § Rails (at its cap).
- [ ] Bulk planners run in waves by `depends-on`: at step 2 the session proposes
  each task's `depends-on` with its slug and mode, the dispatch passes it, the
  planner writes it into the header, and a wave starts once the plans it
  depends on are committed, its planners in parallel (requirement outcome 9).
  Approach: `write-plan.md` § Inputs, step 2 and § Bulk mode, then
  `agents/dev-planner.md` § Inputs and § Steps 4.
- [ ] A code defect the docs step finds - a writer's or verifier's entry the
  code, not the doc, must change - is a `## Review` entry fixed as § Close 2's
  are, before the verifier or the one writer re-dispatch, which brings the doc
  to the fixed code; nothing is reviewed again (requirement outcome 10).
  Approach: `run.md` § Close 3 and § Seats, then the § Outputs of
  `agents/dev-doc-writer.md` and `agents/dev-docs-verifier.md`.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included. (Batch members: the task
  mark rides the batch branch.)

## Claims

- none

## Proven

- none
