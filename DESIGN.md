# Environment design

Architecture of the `~/.claude` framework: the components, how they
relate, and the invariants that keep them coherent.

## Components

- **dev-instructions.md** - global instructions the installed
  `CLAUDE.md` imports. Maintenance: `rules/claude-md.md`.
- **rules/** - path-scoped convention rules; the DEV process rules live
  in `skills/dev/`, not here.
- **skills/** - invocable capabilities: `skills/dev/`, the `/dev` router
  and its mode files (the DEV toolset), and standalone reference
  skills. Authoring: `rules/skills.md`.

## Self-hosting layout

This repository is cloned outside `~/.claude`, and
`scripts/install-dev.sh` copies the framework there, the files it did
not copy being the user's (`scripts/install-manifest.sh`).
`REQUIREMENTS.md`, `DESIGN.md`, `MAINTENANCE.md` and `LAYOUT.md` sit at
the root; the nested `.claude/` holds Claude Code's project settings and
this repository's instructions, its `CLAUDE.md` carrying the declarations;
DEV artifacts sit at the paths `.claude/CLAUDE.md § Layout` declares,
`dev/` here.

## Tree-map

The tree is `LAYOUT.md` (`skills/dev/layout.md § Layout file`).

## Planning model

Self-development uses the planning hierarchy per `skills/dev/plan.md`,
unchanged - structure is never simplified, only description detail. A
plan runs once merged, a small change's once its `approved: yes` header
is committed on its task's branch; a strict plan also needs its cold
read (`skills/dev/branch-plan.md § Modes`).

## Git & delivery model

Trunk-based development, per `skills/dev/git-workflow.md`.

Planned work runs through one flow, `skills/dev/run.md`: a runner
dispatches seats - planner, implementer, reviewer and doc writer -
each a subagent in its checkout with fixed inputs and a one-item
lifetime. Who holds the supervisor seat, the user or the runner, is
declared per project (`skills/dev/companions/declarations.md
§ Supervisor bounds`). The unit of delivery is the batch, a lone task a
batch of one (`skills/dev/branch-plan.md § Agentic execution`).
The runner keeps no record of its own: after compaction it re-derives
its scope's state from the plans, the task reports, git and the MR/PR
state (`skills/dev/run.md § Monitor`). Each change is reviewed once, at its
branch close, or, for a small branch folded into its batch, at the
batch close, which also covers cross-branch concerns (`skills/dev/run.md
§ Close` 1, `skills/dev/batch.md § Batch close` 1). Releases tag the trunk
(`skills/dev/git-workflow.md § Releases`) and run no code review.

Any seat edits a normal plan while the requirements hold; its report
keeps one line per entry and its docs come from the diff. A strict plan
lists its docs' claims, with evidence in the task report
(`skills/dev/companions/documentation.md § Claims`).

Standard: Trunk-Based Development / GitHub Flow (trunkbaseddevelopment.com,
dora.dev); tag-on-trunk releases (Pro Git, git-scm.com).

## Self-enforcement

Two tiers gate every change into `main` (Claude Code hooks reach a
machine only through `install-dev.sh`):

- **Tier-1 - mechanical CI.** `scripts/ci/*.sh`, and the script tests in
  `scripts/test/`, run in `.github/workflows/ci.yml` on
  `pull_request` and locally in the advisory `.githooks/pre-push` via
  `core.hooksPath`; either failing blocks the push or the merge. Each
  `check-*.sh` hard-fails a PR on one kind of break:
  - `check-caps.sh` - a cap violation;
  - `check-stray.sh` - a stray top-level file;
  - `check-plan-integrity.sh` - a plan-integrity break;
  - `check-plan-text.sh` - a changed plan file breaking its text rules
    (`skills/dev/templates.md`) or out of step with its task report;
  - `check-archival.sh` - an unarchived closed initiative;
  - `check-todos.sh` - a `TODO`/`FIXME`/`XXX` marker in code;
  - `check-references.sh` - an expired reference;
  - `check-accretion.sh` - a dated accretion marker;
  - `check-code-size.sh` - an oversized code file or function;
  - `check-no-em-dash.sh` - an em dash;
  - `check-secrets.sh` - a tracked secret (the hook's predicate);
  - `check-batch-tags.sh` - a stale batch ref (local-only);
  - `check-settings.sh` - an unconfigured context budget or bare
    `Bash(git:*)` grant.

  Content checks - caps, code size, em dashes, `TODO` markers,
  accretion, plan text - judge what a branch adds or changes
  over its merge-base with the default branch
  (`scripts/ci/branch-diff.sh`). Tree checks - stray, plan integrity,
  archival, references, batch tags, settings, secrets - judge the whole
  tree, since a branch breaks those from outside the failing file and
  a tracked credential is live at any age. With no base, content
  checks judge the whole tree and plan-text skips. `main` is
  protected: a merge needs a PR with `tier1` green, `enforce_admins`
  on.
- **Tier-2 - AI review.** `MAINTENANCE.md § Tier-2 AI review` applies its
  concerns to the diff at branch close (`skills/dev/branch-plan.md
  § Closing routine`); they are enumerated there and nowhere else.

PreToolUse hooks guard ahead of both tiers: no trunk writes, commits
or pushes, force pushes nowhere, no `checkout`/`switch` into a branch
named as a default branch with uncommitted tracked work, no discard of
tracked work that neither `git stash pop` nor the reflog brings back,
no secrets into tracked files or commits (the secrets guard fails
closed without its pattern library).
The state hooks keep branch and tree in view, and on a compacted or
resumed start re-brief from the tree read at that moment - branch,
status, recent commits and the first open item of each plan the branch
touched; the summary keeps the rest (`dev-instructions.md § Compact
instructions`).

## Context budget

`autoCompactWindow` caps the working context, so cost stops tracking
session length; the gates judge changes, not sessions.

## Invariants

- Every skill is reachable, documented, and non-duplicative.
- No workflow contains a dead-end or an unbounded loop.
- Rules and CLAUDE.md reference only existing paths.
- DEV behaviors change only through an initiative.

## Decisions

Architecture Decision Records, when needed, live in `adr/` (lazy,
per `skills/dev/layout.md`).

- A plan's merge, and for a strict plan its cold read, admit it to a
  run (§ Planning model): a seat asks its question mid-run
  (`skills/dev/run.md § Question resolution`), so nothing certifies
  ahead of the run that a plan leaves none open.
- A small change's plan is admitted unmerged, by a record on its
  branch: the runner keeps no record of its own (§ Git & delivery
  model), so the approval is committed where it reads, and one MR/PR
  ships the requirements, plan and code.
