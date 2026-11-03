---
task: R091-T004
type: mnt
mode: normal
---

- [ ] No seat reads `run.md` for its duties or another file to locate one:
  the six seats lose their `**Duties.**` paragraph, and a citation that only
  locates a file names it. Approach: `agents/*.md`; e.g. the implementer
  names `skills/dev/<type>.md` for its loop in place of `run.md § Dispatch
  per item`, and drops `plan.md § Where things live`.
- [ ] The implementer, planner and cold reader read the docs index and the
  docs covering what the item touches, `DESIGN.md` only for an
  `architecture-changing` plan and `README.md` only for public surface.
  Approach: each seat's `**Docs**` input; the cold reader's "exactly the
  implementer's inputs" line follows.
- [ ] A normal plan's seats and session read no strict-only text: the strict
  rules in `branch-plan.md` (§ Modes, § Task report) and in the seats
  (implementer claims and probes, planner proof, skeleton, gap dispatch)
  move to one file read only under `mode: strict`. Approach: new
  `skills/dev/strict.md`; each seat cites it once; `LAYOUT.md`.
- [ ] A task-scoped run reads no batch-only text: `run.md § Batch close`,
  the batch steps of its other sections and the batch parts of
  `branch-plan.md § Agentic execution` move to one file read only for a
  batch scope. Approach: new `skills/dev/batch.md`; `SKILL.md`'s `/dev plan
  batch` row and every `§ Batches` / `§ Rails` citation follow; `LAYOUT.md`.
- [ ] Complete the branch: cleanup, mark plan complete, mark the task `[x]`
  in the R's `tasks.md`, commit.
