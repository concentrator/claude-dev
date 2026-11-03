# Planning rules

Three-level hierarchy for DEV mode: `R<NNN> → R<NNN>-T<NNN> → branch plan`,
planned in two rounds (§ Planning rounds). An initiative is any work
foundational `.claude/REQUIREMENTS.md` doesn't already cover.

## Levels

1. **Roadmap** - `<plans>/ROADMAP.md` (§ Where things live).
   Initiative index. Items: `R001: description`.
   Each entry owns `<plans>/R<NNN>-<slug>/`, whose `requirements.md`
   carries the initiative's motivation, goals, and acceptance
   criteria (template: templates.md). Closure: see § Approval
   and closure.
2. **Tasks** - `<plans>/R<NNN>-<slug>/tasks.md`, one index per
   initiative, created lazily with the R's first task (an R with no tasks
   has none). Concrete units of work. Items:
   `R001-T001 [feat]: description` - the tag in brackets
   (`[feat] | [fix] | [refactor] | [doc] | [test] | [mnt]`) declares task
   type and determines the branch prefix (`git-workflow.md § Trunk`).
   Checkbox closes only when the task's branch is merged.
   The id itself routes: the
   task's artifacts live in `<plans>/R<NNN>-<slug>/`, or the same path
   under `archive/`. `ROADMAP.md` is the cross-R index - there is no
   flat global task list.
   **Right-size**: a task is a coherent, multi-commit deliverable (a
   self-contained capability or fix), not a single edit - commit-sized
   steps live in the branch-plan checklist. E.g. "add the size-scaled
   close-review policy" (rule + skill wiring + cross-refs) is one task;
   "fix a typo in a rule" is a commit within one, never a task.
3. **Branch plan** - `<plans>/R<NNN>-<slug>/<task-id>-<slug>.md`
   (e.g. `R062-T001-id-gates.md`; legacy `T-XXX-<slug>.md`).
   Checkboxes per commit. Header: `task: R008-T001`. Checkbox closes at
   commit (`branch-plan.md`).

## Planning rounds

Two rounds, each approved at one gate:

- **Shape** (`/dev plan R`) - produce the initiative's `requirements.md`:
  its outcomes and its design - the standard it follows and the
  components it changes (`templates.md § Per-initiative`). No task list.
- **Detail** (`/dev plan R<NNN>`) - produce the open R's task list
  (`tasks.md`) **and** a branch plan per task together.

A **small change** is an initiative of one task, which the user picks
in the shape round (`brainstorm.md` step 2). Both rounds run in that
one session, each still at its own gate, on the task's branch
(§ Where plans live in git).

**Approval authorizes planning, not code** (gate: § Approval and
closure). Approving a plan sends its branch through `finish.md § 3`,
the one decision every branch takes, and the round stops there:
shape-approval authorizes the detail round; detail-approval authorizes
nothing to run. A small change's branch takes no decision at either
gate: it stays open for the code.
A plan round ends by proposing `/dev run <slug>`, which the user
invokes explicitly.

## Proportionality

`dev-instructions.md § Scope` binds here: one observed failure earns one
fix and one test. A test is written when it guards an invariant or pins an
observed failure; doc, config, and plan tasks ship none, and a test
written to satisfy a review expectation is scope creep. Deeper
proofs - mutant cases, unfixed-copy comparisons, vendored-copy
assertions - are reserved for `dev-secrets-guard` and
`dev-branch-guard`. A shape round asks what can be deleted before it
adds.

## ID format

One shape for every id: initiative `R<NNN>`, task `R<NNN>-T<NNN>`,
batch `R<NNN>-B<NNN>` (`branch-plan.md § Agentic execution`). A letter
plus three digits per component, hyphens only between components;
one-indexed, monotonic, T and B counters scoped to the initiative; the
next free id is the highest in its scope plus one, no cross-scope
lookup. A task moving to another initiative closes under its old id with a
one-line tombstone naming the new id; ids are never renumbered. Legacy
shapes - `R-NNN` initiatives, bare `T-NNN` (retired global counter),
`B-NNN` and `R<NNN>-B-NNN` batches - are frozen: valid, never reissued
or renamed. `REQ-XXX` is retired: requirement content carries
its parent's R id (legacy files: § Archival).

## Referential integrity

- Roadmap items are the chain root (dir act: § Directory conventions).
- Tasks reference exactly one parent roadmap item.
- Branch plans reference exactly one parent task (via header).
- Each parent must be **open** (`[ ]`) at the time the child is created.
- Commits inside a branch plan need no external refs.
- Findings promotion too: a finding becomes a task
  only under a fitting open `R<NNN>`. If none exists, create an R stub
  instead - the initiative act per § Directory conventions, shaped
  in a later shape round (`/dev plan R`).
- Only a discovery that blocks the current task's goal becomes a task
  immediately. Anything else is an unnumbered backlog line in the owning
  R's `tasks.md`, one line long, promoted to a task - or dropped - at
  that R's next shape/detail round. A defect gets one line however
  often it is found; the branch that fixes it deletes the line in its
  final commit.

## Where things live

DEV artifacts live at the paths the project's `§ Layout` declares, in
its root `CLAUDE.md` or `.claude/CLAUDE.md`
(`companions/declarations.md § Declared paths`): `<plans>`
(below); the docs tree is `<docs>`
(`layout.md § Docs`) and the repository's actual tree is `<layout>`
(`layout.md § Layout file`). A `CLAUDE.md` still carrying a
`DEV artifacts root:` or `extended-docs:` line is stale; `migrate.md`
(Stale declarations) reports each with its rewrite. Guarded config is
not an artifact: it stays under `.claude/`, `REQUIREMENTS.md` and
`DESIGN.md` included (`layout.md § Config layout`).

The file tree is `layout.md § Artifacts layout`; its locations are
exclusive - never place plans or specs in `<docs>` or other
project directories.

## Directory conventions

- One plan directory per roadmap entry: `<plans>/R<NNN>-<slug>/`, created
  at initiative time - a new initiative is one act: ROADMAP entry +
  dir + `requirements.md` (`approved: pending`). Slug derives from the
  roadmap entry subject, is fixed at creation, and is never renamed on
  roadmap rewording.
- Branch naming: `git-workflow.md § Trunk`.
- `R<NNN>-<slug>/batches/` is created with the R's first batch
  manifest; batches are scoped to that single R (`batch.md
  § Batches`).

## Where plans live in git

Planning artifacts (§ Where things live) live on `main`, visible from
every branch, reaching it via a plan branch + MR/PR like any change
(`git-workflow.md § Trunk`); the plan branch is cut before the first
artifact write. A single planning act still commits each
artifact type separately - `requirements.md` apart from the `ROADMAP`
/ `tasks.md` index edits.

A small change (§ Planning rounds) cuts no plan branch: its branch is
the task's own, `<prefix>/<slug>` from the task's tag
(`git-workflow.md § Trunk`), cut before the first artifact write. It
carries the ROADMAP entry, `requirements.md`, `tasks.md` and the
branch plan.

## Cross-plan dependencies

A branch plan may declare `depends-on: R008-T001` in its header. `/dev run`
refuses to start the branch until the dependency is merged.

## Adjusting existing plans

After the rounds, adjust in place:

- **Initiative requirements** (`<plans>/R<NNN>-<slug>/requirements.md`):
  `/dev plan R<NNN>` to extend.
- **Branch plan (`<slug>`)**: `/dev plan <slug>` edits the plan in the
  session as the user asks, no planner dispatched (`branch-plan.md
  § Plan edits`). An edit is not cold-read again.
- **Roadmap items, tasks** (single-line entries): direct file edit.
- Never rewrite history retroactively.

## Approval and closure

`.claude/REQUIREMENTS.md` and each initiative's
`<plans>/R<NNN>-<slug>/requirements.md` carry a frontmatter `approved:`
field: `pending` when new, `yes` once the user confirms. Nothing
downstream proceeds while pending. The field records which state the
requirements are in, not when they got there - the date of an approval
is in the commit and MR/PR that carried it; which review an approval
came from is resolvable from the commit that added it. A detail round
is offered for approval only with every strict plan's cold read
recorded as `cold-read: passed` (`write-plan.md` step 6), a plan whose
`depends-on` names an unmerged task excepted: it is read at its start.

An R entry closes (`[x]` in ROADMAP) only when **both** hold:

- all child tasks are `[x]`, and
- the user confirms every outcome in its `requirements.md` is met.

The ROADMAP `[x]` is the closure record; the evidence for each outcome
goes in the closing MR/PR body, never in `requirements.md`.

The check runs on the branch completing the R's last open task, in its
mandatory final commit (`branch-plan.md § Closing routine`), judged
against `tasks.md` re-read from `main` - the closure lands with that
branch's merge. A small change, whose `tasks.md` exists only on its
own branch (§ Where plans live in git), is judged against that
branch's, its closure marks riding the same MR/PR. A closure the final
commit could not run - concurrent branches racing past the check, or
run-dependent (later-verified) criteria - keeps the R open and ships
later via its own plan MR/PR once verified (e.g. a batch checkpoint -
`batch.md § Boundary verification`).

## Milestone plans

A milestone spanning several initiatives may carry
`<plans>/milestone-<id>.md` - the second root-level cross-initiative
plan beside the release plan, written via `/dev plan milestone <id>`
(template: `templates.md`). Optional: a milestone inside one
initiative is ordered by that `tasks.md`.

- **Order, never scope.** The boundary lives in an optional
  `ROADMAP.md § Milestones` map - one row per milestone, a one-line
  boundary, citing its plan where one exists; the plan cites the row.
- **Existing task ids only.** A gap the plan names gets a task
  (§ Referential integrity), never a note.
- **`depends-on` is authoritative.** The plan reads the edges into
  waves (a wave has no internal edges, so it runs in parallel) and
  never restates or overrides them; a contradicting order is a defect
  in the milestone file.

## Archival

Archival runs at **initiative** close; a closing task promotes but
never moves files. At close every task report meets one of four
endings: **archived uncited** with its directory; **promoted** - its
durable facts move to their permanent home (component behavior to
docs, external-system facts to adapted references, binding limits to
where they bind); **transformed** into a report doc
(`companions/documentation.md § Diataxis typing`) when its evidence
stays useful as evidence; or **spawned** into a new plan or task it
motivates. A finding another initiative's open task still cites is
promoted before its own R closes. **Archive**: the closing branch's
final commit carries the whole directory's move to
`<plans>/archive/R<NNN>-<slug>/` - requirements, task index, branch
plans, and task reports together - so one delivery closes and archives the
R (Tier-1 `check-archival`; a frontmatter
`archival: deferred - <reason>` defers the move with cause).
Docs never link findings or plan files, live or archived
(`companions/documentation.md § Content quality`): promotion moves
facts, never links. If a doc needs a fact from `archive/`, promotion
missed it; move the fact. (Closure-evidence stamps citing archived
findings are historical, not operative.)

Also archived at the user's option: release plans after the release
ships (offered by the `release` skill), milestone plans with every
entry `[x]` (offered by `/dev plan milestone <id>`), and pre-DEV
legacy artifacts (plan files with no `task:` header). Legacy
`REQ-XXX`: folded into `REQUIREMENTS.md`, files removed (§ ID format).

## Templates

Planning-artifact templates (foundational `REQUIREMENTS.md`,
per-initiative `requirements.md` by `kind:`, release plan, milestone
plan) live in `templates.md`, which carries no `paths:` key: read it
on demand, before writing the file a template instantiates.
