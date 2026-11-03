---
name: dev
description: Use to enter DEV mode for spec-driven, planned, reviewed work.
---

# Dev

DEV mode - strict, spec-driven: plan, then run as dispatched seats.
**Read the mode file a command maps to before acting.** An ask in the
tables below goes to the user through the AskUserQuestion tool, the
candidates the state offers as its options.

## Surface

| Command | Read | Purpose |
|---|---|---|
| `/dev` | - | Route by state (ask if ambiguous) |
| `/dev plan [<target>]` | per target table below | Planning (plan MR/PRs) |
| `/dev run [<scope>]` | `run.md` | Run planned work - a task, a batch or an initiative - as dispatched seats under the declared supervisor; no arg → the open batch, else the next cold-read task |
| `/dev ship` | `finish.md § 3` | Ship the landed branch; else error naming why |
| `/dev release` | `release.md` | Finalize + tag the release (project `release` override or this companion) |
| `/dev migrate` | `migrate.md` | Adopt an existing project into DEV: inventory, then route |
| `/dev start` | `start.md` | Scaffold a new project into DEV |

## `/dev plan <target>`

| Target | Action | Read |
|---|---|---|
| `R` | Shape a new initiative (requirements + design, one gate) | `brainstorm.md` |
| `R<NNN>` | Detail an open initiative (tasks + branch plans) | `plan.md` |
| `<task-id>` / `all` | Branch plan(s) for open task(s) | `write-plan.md` |
| `batch [R<NNN>]` | Compose `R<NNN>-B<NNN>.md` (members, order) for that initiative; no R → ask | `batch.md § Batches` |
| `milestone <id>` | Milestone plan (cross-initiative order) | `plan.md` |
| `<slug>` | Adjust an existing branch plan | `write-plan.md` |
| `release` | Release plan (next semver) | `release.md` |
| (bare) | Ask | - |

Round-gate rules: `plan.md § Planning rounds`.

## Process files

Read where a mode file cites them:

| File | Holds |
|---|---|
| `feat.md`, `fix.md`, `refactor.md` | The implementer's loop per plan `type:` |
| `git-workflow.md` | Branches, commits, MR/PRs, merges, releases |
| `layout.md` | Project layout and the layout file |
| `templates.md` | Planning templates |
| `changelog.md` | CHANGELOG style |
