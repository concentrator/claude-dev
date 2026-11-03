# Branch plan rules

A branch plan is `<plans>/R<NNN>-<slug>/<task-id>-<slug>.md`
(`plan.md § Directory conventions`). One branch = one task. The plan is
complete and committed to `main` **before** the branch is created; a
small change's is committed on its task's branch, which its code joins:
one MR/PR ships its requirements, plan and code (`plan.md § Where plans
live in git`).

## Header

    ---
    task: R008-T002
    type: feat                      # required - task tag; sets branch prefix
    architecture-changing: true     # optional - triggers DESIGN.md
                                    #   update commit
    depends-on: R008-T001           # optional - blocks `/dev run` until merged
    mode: normal                    # required - normal | strict (§ Modes)
    cold-read: passed               # strict only - the dispatcher's read
                                    #   (`write-plan.md` step 6)
    approved: yes                   # small change only - the user's
                                    #   confirmation (`write-plan.md` step 7)
    ---

## Body

The header and a checkbox list, nothing else; a strict plan then ends
on `## Claims` and `## Proven` (`strict.md § Planner`).
Each `[ ]` = one commit, naming the change and
carrying the decisions its docs will need - the doc writer's to read,
never the docs' to cite (`run.md § Seats`). Each item states what the
commit delivers against the requirements, one or a few sentences,
followed by an `Approach:` run-in with the suggested files and order.
An item, with its indented continuation, is at most 6 lines;
`scripts/ci/check-plan-text.sh` fails a longer one. Marks record what
happened, never intent - a commit that didn't land stays `[ ]`.

## Modes

**Normal** (default): the plan says what each item delivers and
suggests how. The implementer probes and decides the route.

**Strict**: the planner proves the plan with a throwaway draft, and a
cold read passes it before it runs. Its rules are `strict.md`, which
only a strict plan's seats and session read.

## Plan edits

The plan is temporary. In normal mode any seat edits it while the
requirements hold - no planner, cold read or approval, minimal text; a
requirement change goes to the user (`run.md § Question resolution`).
In strict mode a change is proposed to the user and applied only on
approval, during a run as an answer in the task report's `## Answers`;
a different route to the same outcome is followed in the code and
reported. Checkbox marks are bookkeeping, not plan edits.

## Commit cadence (all types)

Every pass ends the same way; `feat`/`fix`/`refactor` add their mode
file's loop, `doc`/`test`/`mnt` run this alone:

1. **Verify** - the plan `[x]` and the item's report entries (§ Task
   report) written first, since the plan-text gate scans them; then
   the fast tier green over the tree as the commit will carry it: lint
   plus the declared scoped subset (`companions/declarations.md
   § Declared commands`); the full suite runs once at close
   (`finish.md`).
2. **Docs** - none in this commit: every doc the branch ships -
   `<docs>` with its index, the CHANGELOG `## [Unreleased]` entry under
   `release-routine: yes`, `README.md` for new public surface - is the
   doc writer's, written once per branch at `run.md § Close` 3
   (`run.md § Seats`).
3. **Commit** (`git-workflow.md § Commit messages`); the mark and the
   report entries ride it, never a later commit.
4. **Output** - throughout the pass a command prints only what the
   step needs: a status, a count, a range (`grep -c`, `sed -n`, a gate
   or push silenced with its exit status echoed), never a file already
   in context; an edit replaces one anchored span (`Edit`, or `sed` or
   a script asserting a single match), never a heredoc rewrite of the
   file.

Open `[ ]` items → next pass; last non-final `[x]` → § Closing routine.

## No TODOs in code

Never write `TODO`/`FIXME`/`XXX` in code. Route each at discovery to the
task report or a backlog line (§ Scope discoveries).

## Scope discoveries

Noticed mid-execution, not in the plan.

**Blocker** - proceeding would produce wrong, unsafe, or contradictory
code, the task's premise is invalidated, an item's acceptance is
ambiguous, or verification keeps failing after repeated fixes:
- **Stop.** In normal mode a missing step is the seat's to add
  (§ Plan edits). A blocker the plan can absorb - an ambiguous
  acceptance, a strict plan's missing step - halts the item: the runner
  reverts its uncommitted edits and asks the user (`run.md § Question
  resolution`); the next implementer starts from the answer's commit. An
  invalidated premise halts the branch for the user to route.
  A route question - files, order - is no blocker: decide it in the
  code and report the divergence (§ Plan edits). Never inline-fix
  beyond a true typo in code you're writing.

**Non-blocker** - improvement, refactor idea, tangential test gap, code
smell, naming inconsistency:
- In this branch's scope → fix here as a commit, never deferred to a
  finding.
- Another component's → append to the task report (§ Task report),
  continue coding, triage at close.
- Never silently expand scope.

## Task report

`<task-id>-<slug>.report.md` beside the plan, a working file that lives
as long as the R.

**Normal mode.** The report starts with its first entry, no skeleton.
Each entry is one line, written after its item is checked, only when
there is something to say: `- Item <n>: <divergence or finding>` under
`## Implementer`, `- Item <n>: <answer>` under `## Answers`, and
`- [ ] <item>: <issue> - <file:line>` under `## Review`. No claims or
`Evidence:` lines.

**Strict mode.** The planner writes a skeleton with the plan, and the
seats fill it in the form `strict.md § Task report` gives.

An entry names its item or close step - `Item <n>`, `Review <n>`,
`Close review`. A report holds no dispatch, status, prompt, verdict,
merge or time (`run.md § Monitor`).

The implementer writes its entries in the commit that carries the code,
and marks `[x]` each `## Review` entry its dispatch names in that entry's
own commit (§ Commit cadence). The reviewer is read-only: the runner, or
the session outside a run, writes findings, redos and concerns under
`## Review` and answers under `## Answers` (`run.md § Question
resolution`). At close every `[ ]` becomes `[x]` - fixed, `-> backlog`,
or `won't fix: <reason>` - and the final commit carries the resolved
report. A branch adding a legacy `*.findings.md`, which is otherwise
read as a report, fails `scripts/ci/check-plan-text.sh`.

## Scope changes mid-branch

Normal mode: the session, or the implementer still working, commits a
small fix with its plan item added; no new seat starts. Strict mode: a
change is proposed to the user (§ Plan edits), approved as a `## Review`
entry in a run (`run.md § Dispatch per item` 2), else as new checkboxes.

## Closing routine

Runs when the last non-final `[ ]` turns `[x]`; ends in the final
commit and the hand-off (`finish`).

1. **Close review**: one `code-reviewer` dispatch; its depth follows
   the diff class per the rubric in `agents/code-reviewer.md`, which
   also bounds the agent's conduct. A diff that is entirely
   behavior-preserving code runs `/simplify` instead; mixed diffs go
   to the reviewer, adding `/simplify` only at the user's request.
   A second verification agent only when
   the reviewer reports a Critical finding
   (`companions/verification-policy.md § Verifier isolation`).
   Bookkeeping (plan marks) keys no review. Also the
   **Tier-2 compliance review**: every concern in
   `MAINTENANCE.md § Tier-2 AI review`, over the diff.
2. Validate findings against full project context.
3. Report; the findings are written under the task report's `## Review`
   (§ Task report); request user approval before applying.
4. Apply approved fixes as commits.
5. Capture the branch outcome: a summary against the task's acceptance
   criteria (`finish.md § 2`); surface manual-testing/automation needs
   for the verify (`finish.md § 3` step 4).
6. **Triage the task report** (§ Task report): in-scope items resolve here
   as commits, not deferrals (§ Scope discoveries). For each remaining
   `[ ]`, ask the user through the AskUserQuestion tool:
   - Promote to a task or an R stub (`plan.md § Referential
     integrity` owns the routing)
   - Discard (mark `[x]` with reason: "won't fix")
7. **Docs** - the doc-writer pass (`run.md § Close` 3): the seat brings
   the docs to the plan's claims or, for a plan without `## Claims`, to
   the shipped code and commits them; a strict plan's verifier clears them
   (`companions/documentation.md § Verification gate`; `run.md § Seats`).
   Then the **mandatory final item** of every plan:

   > Complete the branch: cleanup (stale/temp data), mark plan
   > complete, mark the task `[x]` in the R's `tasks.md` plus any
   > release-plan entry, commit. (Batch members: the task mark rides
   > the batch branch, `batch.md § Batch close`.)

   The task mark comes last because the cleanup ahead of it can still
   find work: a `[x]` written before it asserts a completion the branch
   has not reached.

   The commit includes the resolved task report. Closing the R's last
   open task → the closure check (`plan.md § Approval and closure`):
   present its verdict and ask - the closure marks, ROADMAP `[x]`, and
   the archive move (`plan.md § Archival`) land in the final commit only
   on explicit user confirmation, never as a side effect of finishing
   the task. Marks land with the merge; a discard drops them.
8. Invoke `finish`: its § 3 ends the branch in one decision, merge or
   discard (a run reaches it through `run.md § Checkpoint`).

## Architecture-changing branches

Header `architecture-changing: true` → the plan includes a commit updating
`DESIGN.md`. Other branches never touch `DESIGN.md`; any branch that adds
or removes an entry keeps `<layout>` current (`layout.md § Layout file`),
foldable into the final commit without the flag.

## Size cap

A branch runs ~20 commits: warn past 20, prompt to split past 30; a
batch's planned commits split past 30 - subordinate to the short-lived
governor (`git-workflow.md § Delivery cadence`). Override with stated
reason in plan header.

## Session boundary

A seat starts for one item and shuts down at its exit; only the branch
and the plan item carry over to the next seat, and a seat outliving its
item re-bills the finished work on every later call (`run.md § Seats`).
The runner session's unit is the scope it runs (`run.md`): at that
boundary it writes the handoff and asks for `/clear` (`finish.md § 4`).

Doc loading keys to the boundary: one load phase at the unit's
start; sectional reads, not whole files; no re-reads within the
unit; outputs (reports) wait for triage.

## Agentic execution

The **batch** - one or more coupled tasks shipped as one CI-gated
MR/PR - is the unit of delivery to `main` at either scope; a lone task
is a batch of one, its branch the MR/PR. A batch-scoped run
(`run.md`) runs members on a `batch/R<NNN>-B<NNN>` branch and closes
through `batch.md § Batch close`; a task-scoped run closes through
§ Closing routine + `finish`.

A plan is admitted to a run once merged over approved requirements, a
small change's unmerged by its `approved: yes` (§ Header), a strict plan
also needing its `cold-read: passed` record (`run.md § Resolve`).

A batch's composition, close and refs are `batch.md`.

### Rails

- Plan text changes during a run only as § Plan edits allows. No seat
  makes the closing decisions. The
  implementer keeps the code, the plan checkboxes, the task report's
  implementer section and claim entries, and its `## Review` entries' marks.
- Seats never push; the only delivery is the checkpoint-accept
  **CI-gated MR/PR** to origin (`run.md § Checkpoint`).
- No commit on a red fast tier - no exceptions.
- Findings triage defers to the checkpoint.

### Stop conditions

| Event | Action |
|---|---|
| Blocker the plan can absorb (§ Scope discoveries), or an implementer's acceptance-level NEEDS_CONTEXT | Halt the item, ask the user (`run.md § Question resolution`) |
| Blocker invalidating the task's premise | Halt, report |
| Seat reports BLOCKED on a classifier denial (`run.md § Dispatch per item`) | Halt, report; the item's work stands, no planner answering a denial |
| Planner reports BLOCKED or NEEDS_CONTEXT on its re-dispatch | Halt, report |
| Doc writer reports BLOCKED | Halt, report |
| A review's fix round leaves findings open (`run.md § Seats`, loop bound) | Report to the user |
| Tests/lint not green after the implementer's fix attempt | Halt, report |
| Non-blocker discovery | task report (§ Task report), continue |
