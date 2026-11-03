# Batch runs

What a batch adds to `run.md` and `branch-plan.md`. Only `/dev plan
batch` and a batch-scoped run read this file; a task-scoped run never
does.

## Batches

`<plans>/R<NNN>-<slug>/batches/R<NNN>-B<NNN>.md` - ordered member list:

    # R062-B001
    - R062-T001 (<slug>)
    - R062-T002 (<slug>)

Composition only (members, order, mode), never status - task state's
home is the R's `tasks.md`. Open iff a member is `[ ]` there and no
`R<NNN>-B<NNN>.report.md` exists. Composition is a planning write
(`plan.md § Where plans live in git`).

Delivery grouping, not a planning level: a batch is scoped to the R
whose dir holds it - its open, coupled tasks (not independently
shippable). `depends-on` resolves within batch order or merged work; a
cross-initiative need becomes its own R. The checkpoint validates that
R's acceptance criteria. The `branch-plan.md § Size cap` governor
bounds the batch.

## Pre-flight

Tag `pre-R<NNN>-B<NNN>` (e.g. `pre-R062-B001`), the rollback anchor,
and create `batch/R<NNN>-B<NNN>` off the latest default branch. Member
branches merge into the batch branch only; the default branch is
untouched until the batch MR/PR merges.

## Per-branch close

The close review (`run.md § Close` 1) runs only above the close-folding
threshold (`companions/verification-policy.md § Close folding`), a
branch with a `probe` claim never being small. The doc-writer pass
(`run.md § Close` 3), the mandatory final commit and a green fast tier
hold regardless of size; the branch then merges into
`batch/R<NNN>-B<NNN>` in place of `run.md § Close` 5's task-scope
step, and the full suite runs at § Batch close.

## Batch close

When the last member is merged into the batch branch:

1. Full-diff review vs default (`code-reviewer`, at the review's cost):
   each folded small branch vs its plan, as its one review, then
   cross-branch interactions, duplicated helpers, convention drift; a
   branch `run.md § Close` 1 reviewed is not checked against its plan
   again. A folded-branch defect beyond batch-branch fixup halts and
   reports.
2. Fixes land as batch-branch commits; queue judgment calls. The runner
   writes each fix as a `## Review` entry of the task report of the member
   whose code it changes, the last in batch order when it changes
   several. Each member with entries then takes one fresh implementer,
   in batch order, which commits them as `run.md § Close` 2 does.
3. Run `Test (full)` - the batch's one full local run; red → halt.
4. Mark member-task checkboxes as commits on `batch/R<NNN>-B<NNN>`
   before the MR/PR (marks per `branch-plan.md § Closing routine`).

Then `run.md § Checkpoint`: its accept opens the MR/PR unasked and
`run.md § Merge or ask` decides it.

## Boundary verification

Added to `run.md § Boundary verification`:

- Before its CI check, `batch/R<NNN>-B<NNN>` has moved off
  `pre-R<NNN>-B<NNN>` (one `git log -1` on each): equal refs mean no
  member branch merged in, so the work took another route, with every
  gate on that route unrun.
- A batch closing an R does **not** carry the closure and archival
  marks - they ride a close-out plan MR/PR (`plan/r<NNN>-close`)
  opened after the batch MR/PR merges, with the release marking.
  Verify that the batch left them alone and that the close-out is
  queued; a batch marking the R `[x]` in ROADMAP has closed on an
  unverified criterion, since CI-green criteria are only verifiable on
  the MR/PR the batch itself creates (`plan.md § Approval and
  closure`, `§ Archival`).

## Refs

Branch refs stay until the batch MR/PR's decision (`run.md § Merge or
ask`). Merge = delete the `pre-R<NNN>-B<NNN>` tag and member refs;
post-merge cleanup deletes the local batch branch, the host the origin
one (`finish.md § 4` step 4). Discard = delete the batch branch
(`finish.md § 3`); tag and member refs stay for salvage.
