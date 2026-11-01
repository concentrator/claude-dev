# Finishing a Development Branch

Close out a task-scoped run's branch - the close step `run.md § Close`
invokes after the mandatory final commit; its § 1 verify set is the
run's evidence (`companions/declarations.md § Supervisor bounds`). § 3
holds the branch's one decision point, merge or discard, taken by the
merging seat (`run.md § Seats`, the Merging row) under either
supervision.

## 1. Verify

- `<plans>/R<NNN>-<slug>/<task-id>-<slug>.md`: every `[ ]`
  is `[x]`; task report triaged.
- Bookkeeping marks landed in the closing commits (`branch-plan.md
  § Closing routine`; untracked: `companions/untracked-claude.md`).
- Close review per `branch-plan.md § Closing routine`.
- Fresh `Test (full)` green (`companions/declarations.md § Declared
  commands`) - the branch's one full local run; failing → stop and
  report.

## 2. Report outcome

What the branch produced vs the task's acceptance criteria. The report
asks nothing; § 3 follows it.

## 3. Ship

The one path from a landed branch (every planned commit in, nothing
uncommitted) to its decision. `/dev ship` enters it directly; on the
default branch, or with uncommitted changes, it stops with an error
naming that condition.

1. Gate: the declared `Test (fast)` and `Test (full)` commands, the
   fast tier carrying the gates an install appends (`start.md § 4`) -
   already satisfied by the last commit's fast run and a § 1 full run,
   with no commit after them. CI on the MR/PR is the authority; a local
   failure stops Ship and is reported.
2. `git push -u origin <branch>`, then open a CI-gated MR/PR via the
   declared change-request command, unasked (`companions/declarations.md
   § Declared commands`; no declared host → push and print the URL).
   **Stay on the branch** - do not switch to the default branch while
   the MR/PR is open, so the reviewer sees the branch's files; the
   switch to default is §4, after merge.
3. Wait on CI in the background (`git-workflow.md § Merge order`).
4. **Verify** - a distinct, blocking step, never folded into the
   decision or glossed past: run the action the diff content calls for
   and show the results. Code → run it live; rules or process prose →
   dry-run the changed rule against a real case; tests → the suite run
   is the verification; data or config → run the work product.
5. **Decision** - the merging seat merges or discards, on the MR/PR
   number, its pipeline state and the verify's results; the user's
   decision is asked through the AskUserQuestion tool:
   - **Merge** via the declared merge command, then §4. Its REST form
     takes `<sha>`, the head sha the CI wait's outcome line named and
     the state check matched (`run.md § Boundary verification` 4).
   - **Discard** - list branch, commits, plan state; a user's discard
     is confirmed by typing `discard`. Close the MR/PR, checkout
     default, delete the branch local and origin. The task stays `[ ]`;
     ask through the AskUserQuestion tool whether to keep the plan.

   No answer leaves the MR/PR open.

Ship ends with one line: MR/PR number and final state - merged,
discarded, or open awaiting the decision.

## 4. Post-merge (after the branch merges)

Detect the merge via the declared state-check command
(`companions/toolchain.md § State check`; no declared host → confirm
the merge with the user), then:

1. Sync the default branch. When `git status --porcelain` prints
   nothing, `git checkout <default>`, then `git pull`. Otherwise stay on
   the merged branch, fast-forward the local default with `git fetch
   origin <default>:<default>`, and name the dirty paths for the user.
2. Promote any durable fact the closed task's artifacts established
   (`plan.md § Archival`).
3. When the merge closed the initiative, verify the archive move
   landed with it (`plan.md § Archival`; Tier-1 `check-archival`).
   A follow-up plan MR/PR carrying the move and closure remains only
   for a late closure already on the trunk - tasks all `[x]` with the
   closure unrecorded and the closure check verifying (`plan.md
   § Approval and closure`).
4. Delete the merged branch locally, once step 1 has moved off it; on a
   dirty tree, where step 1 stays on it, name the branch for the user
   to delete. The merge command only merges: the project relies on its
   host to delete the merged branch on origin.

Bookkeeping landed with the merge (`branch-plan.md § Closing routine`;
untracked mode: `companions/untracked-claude.md`); late closures:
`plan.md § Approval and closure`. Post-merge done, the task ends; the
runner's unit is its scope (`branch-plan.md § Session boundary`).
