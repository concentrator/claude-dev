# Claude Code Environment

Portable, version-controlled Claude Code configuration behind a
spec-driven development workflow, each part listed under § Contents.

## Contents

| Path | Role |
|---|---|
| `README.md` | This file: what the repo is, how to set it up, how the workflow runs |
| `dev-instructions.md` | Global operating instructions; the installer ships it and `@import`s it from the target's `CLAUDE.md`, so it loads every session |
| `writing.md` | Universal writing conventions; the installer ships it and `@import`s it from the target's `CLAUDE.md` as it does `dev-instructions.md` |
| `.claude/settings.json` | Project-tier Claude Code config: the push deny carve-out, branch-push allows, durable tool allows, model override, `autoCompactEnabled` and `autoCompactWindow` |
| `.claude/CLAUDE.md` | This repository's own instructions: its `## Agent toolchain`, `## Supervision` and `## Layout` declarations |
| `rules/` | Path-scoped convention rules, one file per concern; `LAYOUT.md` lists each, and § Installing the toolset elsewhere names the ones the installer ships |
| `skills/` | Invocable capabilities - `dev/` is the /dev router + its mode-file companions (the DEV toolset); beside it the bundled dependency skills the installer ships, and this repository's own runbooks, which it does not ship - `worker-host/` for the worker host and `dogfooding/` for a dogfood run of the toolset ([`install-dev.sh` `BUNDLED`](scripts/install-dev.sh)); `LAYOUT.md` marks each |
| `agents/` | Subagent definitions for the seats of `/dev run`, one per seat the run dispatches (the roster: `skills/dev/run.md § Seats`): each declares the seat's tools and, where it sets one, its model, and is the seat's one contract - `## Inputs`, `## Steps`, `## Outputs` - and a dispatch passes only the values its `## Inputs` names |
| `hooks/` | The Claude Code hooks the installer registers in the target's `settings.json` - the PreToolUse guards and the session-lifecycle hooks - and the helpers they call; `LAYOUT.md` lists each hook with the event it runs on |
| `scripts/` | The Tier-1 gate - `ci/` the mechanical checks and `test/` the script tests, each behind a `run-all.sh`, which CI runs on every pull request (`DESIGN.md § Self-enforcement`) - and the standalone scripts beside it; `LAYOUT.md` lists each script with what it does, and `skills/worker-host/` documents the worker-host ones |
| `.github/`, `.githooks/`, `.gitignore` | The CI gate on pull requests, its advisory local pre-push mirror, and the ignore rules for local overrides, the machine-local project tier, OS files, secrets and bytecode |
| `.env.example` | Template for the worker-host tokens; `.env` itself is never tracked |
| `REQUIREMENTS.md` | What this environment is for and how success is judged |
| `DESIGN.md` | Architecture, self-hosting layout |
| `LAYOUT.md` | The repository's actual tree - the layout file `.claude/CLAUDE.md § Layout` declares; `scripts/ci/check-stray.sh` checks every tracked top-level entry against it |
| `MAINTENANCE.md` | The Tier-2 AI review's concerns (`§ Tier-2 AI review`), the time-based sanity routine (`§ Routine`), and this repository's backlog (`§ Backlog`) with the prompt of the weekly cloud routine that audits the repository against Claude Code's current defaults and docs and proposes each new finding as a backlog line, in a pull request it opens and leaves unmerged ([`§ Weekly audit`](MAINTENANCE.md#weekly-audit)) |
| `dev/` | This repo's own DEV artifacts: `plans/` (the roadmap index, per-initiative `R<NNN>-<slug>/` dirs, `archive/` for closed initiatives) |
| `docs/` | The docs tree: `reports/` holds the probe reports a README claim cites |

## Workflow

Two modes, defined in `dev-instructions.md`:

- **VIBE** (default) - freestyle, no ceremony.
- **DEV** - entered via `/dev`: initiatives (requirements) → tasks →
  branch plans → commits, every level traceable
  (`R<NNN> → R<NNN>-T<NNN> → branch`). Task ids are composite, with the
  task counter scoped to its initiative, so the id routes to the
  artifacts: task `R<NNN>-T<NNN>` lives in `R<NNN>-<slug>/` under the
  plans tree (§ DEV artifacts; `dev/plans/` here), or in
  `archive/R<NNN>-<slug>/` under it once the initiative closes.

Planning takes two rounds: `/dev plan R` writes an initiative's
requirements and design, and `/dev plan R<NNN>` writes its task list
with a branch plan per task
([`plan.md § Planning rounds`](skills/dev/plan.md#planning-rounds)). A
plan merges to `main` before its branch is cut, and `/dev run` admits
only a merged plan. A small change, an initiative of one task, instead
ships its requirements, plan and code in one MR/PR: its plan is
committed on its task's branch, and `/dev run` admits it unmerged by
`approved: yes` in the plan's header
([`branch-plan.md` opening and `§ Agentic execution`](skills/dev/branch-plan.md#agentic-execution),
[`run.md § Resolve`](skills/dev/run.md#resolve)).

Execution is `/dev run`: a task, a batch or an initiative runs as dispatched seats -
subagents, each started fresh for one item and shut down at its exit -
under the supervisor the project declares, human or AI, within
declared bounds. Before its first dispatch a run resolves the
permission set the toolset declares against the three settings tiers a
session reads: `scripts/preflight-permissions.sh` checks only the rules
that bind in the run's permission mode, each reported with the tier
carrying it
([`preflight-permissions.sh` `resolve`](scripts/preflight-permissions.sh)).
A gap halts the run, with one exception: under `Supervisor: human` the
user answers a permission prompt, and a missing allow rule halts no run
([`run.md § Seats`](skills/dev/run.md#seats), the "Clearing a
permission prompt" row). When every gap is a missing allow rule the
pre-flight prints the `--apply` command that closes them; a missing
deny, or any other gap `--apply` cannot write, is closed by hand.
Each rule the pre-flight derives from a declared state-check, CI-wait
or merge line reaches no `gh api` write but the declared merge, and no
merge rule admits `gh pr merge <n> --admin`: the rule for a REST host
command, a shipped script that a project whose host CLI has REST only
declares by its installed path ([§ DEV artifacts](#dev-artifacts)), is
that path, and beside a derived `Bash(gh pr merge:*)` rule the
pre-flight requires the deny `Bash(gh *--admin*)`
([`preflight-permissions.sh` `toolchain_rules`](scripts/preflight-permissions.sh),
[`preflight-permissions-toolchain.test.sh`](scripts/test/preflight-permissions-toolchain.test.sh)).

`skills/dev/companions/auto-mode.template.json` holds the `autoMode`
entries a DEV run needs, for the user to copy into their user settings,
`~/.claude/settings.json`
([`auto-mode.template.json`](skills/dev/companions/auto-mode.template.json),
[`declarations.md § Supervisor bounds`](skills/dev/companions/declarations.md#supervisor-bounds),
[`seat-permissions.md § Auto-mode template`](skills/dev/companions/seat-permissions.md#auto-mode-template)):

- an environment entry describing a DEV run;
- soft_deny entries for the action-level classes of the always-ask list
  of `declarations.md § Supervisor bounds`:
  - DEV Release;
  - DEV Instruction Change, which, like that list's instruction-file
    class, exempts only a `CLAUDE.md` change confined to its
    `## Layout` lines;
  - DEV Customer Data;
  - DEV History Rewrite;
  - DEV Red Gate;
- no allow entry.

Under `auto`, a `Supervisor: AI` runner's merge needs an allow rule for
the declared merge command in a settings tier the session reads, the
rule the checkpoint-push carve-out's first pattern, "Narrow the deny",
shows: `Bash(gh pr merge:*)` in its allow list and `Bash(gh *--admin*)`
in its deny list, or a REST merge script's path with no deny
([`toolchain.md § Permission carve-out for the checkpoint push`](skills/dev/companions/toolchain.md#permission-carve-out-for-the-checkpoint-push)).
A merge that allow rule matches does not reach the classifier, so none
of the soft_deny entries above judges it: the always-ask merges are held
by `run.md § Merge or ask`, which names the MR/PR's delivery class
before any merge and asks the user outside it, and by the host's
required checks
([`seat-permissions.md § Auto-mode template`](skills/dev/companions/seat-permissions.md#auto-mode-template),
[`run.md § Merge or ask`](skills/dev/run.md#merge-or-ask)).

At a branch's close and at a batch's, a run dispatches the code
reviewer, the seat that reviews the change against its plan. A project
sets that reviewer's model and effort with a `review: <model> <effort>`
line in the `## Conventions` section of its own `CLAUDE.md`; without
the line, the reviewer's definition, `agents/code-reviewer.md`, sets
them
([`verification-policy.md § Models`](skills/dev/companions/verification-policy.md#models)).

`/dev ship` takes a landed branch (every planned commit in, nothing
uncommitted) to its MR/PR decision, one of:

- merged
- discarded
- left open awaiting the decision

A failing local gate stops it before the MR/PR opens. A task-scoped
`/dev run` ends on the same path once its checkpoint is accepted;
`/dev ship` enters it directly. On a compacted or resumed start, the
SessionStart hook injects the branch, its working-tree state, its
recent commits and the first open item of each plan the branch touched
([`dev-session-brief.sh`](hooks/dev-session-brief.sh)). Other
commands:

- `/dev start` scaffolds a new project into DEV; in a repository whose
  `main` already exists it delivers the scaffold through a working
  branch and an MR/PR
  ([`start.md` opening and `§ 5`](skills/dev/start.md#5-commit)).
  It writes no settings file: it prints the permission rules for
  `.claude/settings.json` and, under `Supervisor: AI`, the `autoMode`
  entries for `~/.claude/settings.json`, each with its content, for the
  user to write
  ([`start.md § 4`](skills/dev/start.md#4-quality-infrastructure)).
- `/dev migrate` adopts an existing project into DEV.
- `/dev release` finalizes and tags a release.

Command surface and mode files: `skills/dev/SKILL.md`.

## DEV artifacts

Two trees: guarded config - what instructs agents - under `.claude/`,
and agent-authored artifacts at the paths the project's `§ Layout`
declares, one line per key:

- `Docs:` the docs tree
- `Plans:` the planning tree
- `Layout:` the layout file holding the repository's actual tree

A missing path line or `§ Layout` block means that key's default, so a
project that has not declared keeps working.

All of a project's declarations - the `§ Agent toolchain` commands, the
`§ Supervision` seat and the `§ Layout` paths - sit in its own
instructions, the root `CLAUDE.md` or `.claude/CLAUDE.md`, each key
once across the two and the `§ Agent toolchain` block whole in one of
them; the global instructions hold none. A script or hook that reads a
path reads both files, the root one first, and takes the first line
found; the `/dev run` permission pre-flight reads the `§ Agent
toolchain` section of each file. A project declares its CI wait
command in its `§ Agent toolchain`
([`§ Declared commands`](skills/dev/companions/declarations.md#declared-commands)).
The GitHub CI wait, `gh pr checks <n> --watch`, exits 0 when every
check passes and non-zero when one fails
([probe report](docs/reports/gh-pr-checks-watch.md)). Declaration form:
`skills/dev/companions/declarations.md`, the path defaults in its
`§ Declared paths`; canonical structure: `skills/dev/layout.md`; paths:
`skills/dev/plan.md § Where things live`.

Where the host CLI has REST only, every `gh pr` subcommand fails with
HTTP 403 "GraphQL is not available"
([dogfood report](docs/reports/dev-dogfood-report.md)), so the project
declares the shipped REST scripts as its host commands, each by its
installed path: `~/.claude/scripts/<script>`, or
`.claude/scripts/<script>` for a project installed with `--project`
into `<path>/.claude`. That path is the script's pre-flight rule
([`toolchain.md § State check`](skills/dev/companions/toolchain.md#state-check)).
`rest-state-check.sh` and `rest-merge.sh` check their arguments, then
`exec` the one `gh api` call their probe report ran, so each report's
call is its script's
([`rest-state-check.sh`](scripts/rest-state-check.sh),
[`rest-merge.sh`](scripts/rest-merge.sh)); `rest-ci-wait.sh` was
probed as the script itself:

- the state check, `~/.claude/scripts/rest-state-check.sh <n>`, prints
  a pull request's state, merge time and head sha from one REST call,
  making no GraphQL request
  ([probe report](docs/reports/rest-state-check.md));
- the CI wait, `~/.claude/scripts/rest-ci-wait.sh <n>`, exits 0 when
  every check passes and non-zero when one fails, making no GraphQL
  request ([probe report](docs/reports/rest-ci-wait.md));
- the merge, `~/.claude/scripts/rest-merge.sh <n> <sha>`, merges a
  pull request with a merge commit from one REST call carrying the
  head sha CI verified, making no GraphQL request, and exits non-zero
  when the host refuses the merge, a head moved past that sha included
  ([probe report](docs/reports/rest-merge.md)).

An explanation the user gives or a conclusion an agent reaches goes,
on the user's approval, to the home owning its kind: `CLAUDE.md` for a
convention or a project detail, `DESIGN.md` for architecture, the plans
tree for a planned change, and the docs tree or its `references/`
subdirectory for behavior
([`§ One home per finding`](rules/writing-artifacts.md#one-home-per-finding)).

## Self-hosting

This repo manages itself with the same DEV discipline it provides:
changes to the environment flow through initiatives in its plans tree
like any other project. This repository's own instructions, its
declarations, sit in `.claude/CLAUDE.md`. The foundational
files live at the root, `LAYOUT.md` among them, so `.claude/CLAUDE.md
§ Layout` declares `LAYOUT.md` there and keeps `Docs:` and `Plans:` at
their defaults: the DEV artifacts
sit beside the root files under `dev/` - see `DESIGN.md § Self-hosting
layout`.

`MAINTENANCE.md § Doc-sync pairs` maps each path glob to the files that
an added, removed or renamed path it matches must update
([`§ Doc-sync pairs`](MAINTENANCE.md#doc-sync-pairs)).
`scripts/ci/check-doc-sync.sh` fails a branch that adds, removes or
renames a path a doc-sync row matches without changing every file the
row names ([`check-doc-sync.sh` `hits`](scripts/ci/check-doc-sync.sh)).

## Setup on a new machine

1. Clone the repository to a directory that neither is nor contains
   `~/.claude`: an install refuses a target inside the checkout it
   runs from
   ([`install-dev.sh`](scripts/install-dev.sh)).
2. From the clone, run the global install, `scripts/install-dev.sh`,
   which copies the toolset into `~/.claude` (§ Installing the toolset
   elsewhere).
3. Arm the advisory local gate: `git config core.hooksPath .githooks`,
   once per clone, so `.githooks/pre-push` runs Tier-1 - the checks and
   the test suites - before a push leaves the machine.
4. For each skill you keep in its own repository, clone that
   repository and link the skill's directory into `~/.claude/skills/`:
   `ln -s <clone>/<skill-dir> ~/.claude/skills/<name>`.

A Claude Code cloud session gets the toolset from its environment's
setup script, which shallow-clones the toolset outside `~/.claude` and
runs the global install, so no command of the session installs it
([`preparation.md` step 4](skills/dogfooding/companions/preparation.md)).
That step is where the dogfood run sets its environment up; outside a
run, an environment carries no such script until you write it:

1. Resolve the toolset commit to its full 40-character sha. A branch
   resolves with the command below, and a full sha is its own; an
   abbreviated sha fails the script's fetch.

   ```bash
   git ls-remote https://github.com/concentrator/claude-dev refs/heads/<branch> | cut -f1
   ```

2. Set the cloud environment's setup script to the lines below, that
   sha in place of `<TOOLSET_SHA>`. The clone sits outside `~/.claude`,
   since the install refuses a target inside the checkout it runs from.

   ```bash
   set -e
   git clone -q --depth 1 --no-checkout https://github.com/concentrator/claude-dev ~/src/claude-dev
   cd ~/src/claude-dev
   git fetch -q --depth 1 origin <TOOLSET_SHA>
   git checkout -q --detach FETCH_HEAD
   bash scripts/install-dev.sh
   ```

3. Make that environment the account's default, so a new session
   starts in it.

To move the toolset, write the new sha into the script: the environment
reruns its setup script only when the script changes, and starts later
sessions from the first run's cached result, so a branch name in the
script would keep that run's commit.

The install runs in the setup script because a session in the `auto`
permission mode cannot run it itself: the permission classifier
refuses a session's own `bash scripts/install-dev.sh` with the reason
"Code from External", and a copy of its files by hand with the reason
"Auto-Mode Bypass"
([`dev-dogfood-report.md`](docs/reports/dev-dogfood-report.md)).

## Installing the toolset elsewhere

Run from a checkout of this repo, the installer copies the DEV toolset
to a target outside that checkout, the machine's `~/.claude` or a
project's `.claude/`:

    scripts/install-dev.sh                   # into ~/.claude (global)
    scripts/install-dev.sh --project <path>  # into <path>/.claude

A full install ships:

- `skills/dev/` whole: the `/dev` router and its mode-file companions.
- The bundled dependency skills the companions reference by name, the
  `BUNDLED` list in `scripts/install-dev.sh`.
- The seat definitions under `agents/`, the subagents `/dev run`
  dispatches
  ([`install-dev.sh` `ship_tree agents`](scripts/install-dev.sh)).
- `writing.md`, the writing conventions, and `dev-instructions.md`, the
  framework's global instructions
  ([`install-dev.sh` `IMPORTS`](scripts/install-dev.sh)).
- From `rules/` only these:
  - `writing-artifacts.md`, the DEV-artifact writing rule.
  - `code-comments.md` and `claude-md.md`, the rules the shipped skills
    and seat definitions cite
    ([`install-dev.sh` `CITED_RULES`](scripts/install-dev.sh)).
- The project-agnostic Tier-1 checks, into `scripts/ci/`:
  - `check-code-size.sh`, plus an empty `code-size-allow.txt` when the
    target has none.
  - `check-no-em-dash.sh`.
  - `check-accretion.sh`, with its self-test.
  - `check-batch-tags.sh`, with its self-test.
  - `check-plan-text.sh`, with its self-test.
  - `check-archival.sh`, the gate failing a closed initiative left
    unarchived, with its self-test
    ([`install-dev.sh` § 4](scripts/install-dev.sh),
    [`check-archival.sh` `status: done` loop](scripts/ci/check-archival.sh)).
  - `branch-diff.sh`, without a self-test: the helper that every check
    above except `check-batch-tags.sh` and `check-archival.sh` loads
    from the check's own directory. A check that cannot load the helper
    fails, exiting 1.
- `scripts/preflight-permissions.sh`, the `/dev run` permission
  pre-flight, with its self-test.
- `scripts/rest-state-check.sh`, `scripts/rest-ci-wait.sh` and
  `scripts/rest-merge.sh`, without self-tests: the host commands a
  project whose `gh pr` has no GraphQL declares
  ([`toolchain.md`](skills/dev/companions/toolchain.md)).
- The hooks below.
- On a `--project` install, the maintenance hygiene section, seeded
  into the target's `MAINTENANCE.md` when that heading is absent.

The installer registers these hooks in the target `settings.json`,
creating the file as `{}` when the target has none. Otherwise it writes
that file only to add a missing entry for one of them, to replace one
given in the relative form `.claude/hooks/<name>`, or to drop a retired
hook's entry
([`install-dev.sh` `edit_settings`](scripts/install-dev.sh)):

| Hook | Event | Matcher |
|---|---|---|
| `dev-branch-guard.sh` | PreToolUse | `Write\|Edit\|NotebookEdit` and `Bash` |
| `dev-secrets-guard.sh` | PreToolUse | `Write\|Edit\|NotebookEdit` and `Bash` |
| `dev-branch-state.sh` | UserPromptSubmit | none |
| `dev-session-brief.sh` | SessionStart | `compact\|resume` |

The installer also copies these files beside the registered hooks,
unregistered, each used by a registered hook:

- `secret-patterns.sh`, the secret predicate the secrets guard sources.
- `dev-hook-once.sh`, the check every registered hook sources to skip a
  run the global settings already make.

A hook in a project's `.claude/hooks/` exits silent when
`~/.claude/settings.json` registers the same hook, as
`~/.claude/hooks/<name>` or its expanded path, for the same event under
a matcher that covers the call, so a project that also has a global
install runs each hook once. For the guards the matcher covers the call
when it matches the tool name, for the session brief when it matches
the start's source. For the branch-state hook only a missing, empty or
`*` matcher covers it, or one that matches the empty string. The project copy acts as usual when that settings file is
absent or unparsable, `jq` is missing, or `dev-hook-once.sh` is.

`--minimal` serves contributors who work a project's existing plans
without `/dev`. It ships the full set less the seat definitions,
`rules/code-comments.md`, `rules/claude-md.md` and two parts of
`skills/`: no bundled dependency skills, and from `skills/dev/` only
these files:

- `finish.md`
- `git-workflow.md`
- `companions/declarations.md`
- `companions/toolchain.md`
- `companions/untracked-claude.md`
- `companions/secrets.md`
- `companions/auto-permissions.template.json`, the permission
  pre-flight's input

A `--project` install into a git repo refuses a dirty tracked tree or a
default-branch HEAD, so the copy ships as its own reviewable change;
`--force` bypasses the guard.

Global install serves a contributor who wants `/dev` everywhere; the
`--project` copy serves a repo's no-global contributors (skill precedence
means a contributor's own global copy still wins). Re-run the installer
to refresh.

An install records each file it copies in a manifest in the target,
`dev-install-manifest.txt`. It adopts and refreshes a target file whose
hash matches its manifest record or, unrecorded, any committed version
of its path in this repository; any other target file that differs from
the shipped copy it leaves in place and lists. By the same test it
removes a target file the set no longer ships - a recorded file, a
retired hook, and, with no manifest in the target, any file under the
trees it ships whole - when it is the install's copy, and leaves and
lists any other
([`install-manifest.sh` `copy_shipped`, `owned`, `committed`, `install_shipped`, `drop_unshipped`, `list_kept`](scripts/install-manifest.sh)).

Beyond the copied files it appends, in both cases, an `@writing.md`
line and an `@dev-instructions.md` line, each when absent, to the
install directory's `CLAUDE.md` (`~/.claude/CLAUDE.md`;
`<path>/.claude/CLAUDE.md` under `--project`)
([`install-dev.sh` `IMPORTS`](scripts/install-dev.sh)), and - for `--project` -
to the repo's root `.gitignore`: a `!`-allowlist line for each
installed path that repo ignores, so the toolset stays committable.
A `--project` install into a git repo, full or `--minimal`, also wires
the plan-text and code-size gates into the fast tier: it appends, in this order,
`` , then `bash <prefix>.claude/scripts/ci/check-plan-text.sh` `` and
`` , then `bash <prefix>.claude/scripts/ci/check-code-size.sh` `` to the
repo's `Test (fast):` line, else to its `Test:` line, in whichever of
the repo root's `CLAUDE.md` and `.claude/CLAUDE.md` holds it, the root
one's when both do (the last line of a wrapped one, its closing period
dropped), keeping the file's mode. `<prefix>` is `<path>` relative to
the repo root: empty when `<path>` is the root, `sub/` for `--project
<repo>/sub`. Each gate is appended only where none of the line's lines
names its script yet, so a re-install adds a missing gate and leaves a
line naming both as it is. With neither line in either file, no
fast-tier line is written and the install prints one line naming both
files and the line to add, both gates included. A global or non-git
install touches no fast-tier line; its only `CLAUDE.md` writes are the
two import lines above. Past the import lines and that fast-tier
append, an install leaves the
declarations and the layout file exactly as it found them: they are the
project's.
The copied checks are yours to wire into CI; the installer ships them
without registering them and edits no CI config. A `--project` install into
a git repo prints one line saying the project's CI must run the fast tier,
which is what runs the two gates there.

The copied checks in the table below judge only what the working
tree adds over a base: committed, staged and unstaged changes, and
untracked files git does not ignore. The base is the merge-base of
`HEAD` with the first of these refs that has one:

1. `origin/main`
2. `origin/master`
3. `main`
4. `master`

The plans directory below is the one the `Plans:` line of the repo
root's `CLAUDE.md` or `.claude/CLAUDE.md` declares, else `dev/plans`.

| Check | Files it judges | With no merge-base |
|---|---|---|
| `check-code-size.sh` | code files, by the extensions in `\.(sh\|bash\|js\|mjs\|cjs\|jsx\|ts\|tsx\|py\|go\|rb\|rs)$` | every tracked file of that scope, whole |
| `check-no-em-dash.sh` | every text file | every tracked text file, whole |
| `check-accretion.sh` | `*.md` files under the plans directory, its `archive/` excluded | every tracked file of that scope, whole |
| `check-plan-text.sh` | plan files under the plans directory, its `archive/` excluded | none: it prints `check-plan-text: SKIP (no default branch)` and passes |
