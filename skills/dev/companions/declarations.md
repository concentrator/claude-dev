# `CLAUDE.md` declarations

The keys a project declares - routine commands in `§ Agent toolchain`,
supervision in the `§ Supervision` that follows it, and paths in the
`§ Layout` after them - and the exact form each takes. All apply
everywhere - both modes, every command. Push and MR/PR mechanics that
consume them: `toolchain.md`.

The declarations sit in the project's own instructions, the root
`CLAUDE.md` or `.claude/CLAUDE.md`, each key once across the two, the
`## Agent toolchain` block whole in one of them; the global
instructions hold none. Every script and hook that reads a key reads
both files and takes the first line found.

## Declared commands

A project declares its routine commands in an `## Agent toolchain`
section - the VCS host (→ `gh`/`glab`) and the exact
change-request / merge / state-check / CI wait / test / lint / build
commands, the state check on a `State-check:` line in a form
`toolchain.md § State check` gives - its REST form where `gh pr`
answers HTTP 403 "GraphQL is not available" - the CI wait on a
`CI wait:` line in the form `toolchain.md § CI wait` gives, and the
merge on a `Merge:` line in the form `toolchain.md § Merge` gives. It
is the single source the run reads:

- `/dev run` uses it for `permissions.allow` (the pre-flight gate in
  `toolchain.md § Permission carve-out for the checkpoint push`).
- `finish` runs the declared commands instead of probing the host.

The test declaration is tiered, and both tiers include lint.
`Test (fast)` - lint plus a scoped subset of the suite (the tests
covering the area a commit touches) - runs per commit; `Test (full)` -
lint plus the whole suite - runs once at branch close
(`finish.md § 1`), and CI on the MR/PR is the authority. A single
`Test:` declaration serves as both tiers; a project with no scoped
subset declares fast as lint only.

Declare it once; `migrate` backfills it if absent (absent-host fallback:
`finish § 3`).

## Supervisor bounds

A project delegating delivery to a supervisor declares who holds the
seat and its bounds in a `## Supervision` section directly after
`## Agent toolchain` - the single home for merge authority:

```
- Supervisor: AI
- Supervisor bounds: batch-scoped delivery; instructions: .claude/supervisor.md
```

`Supervisor: human` - the user's own interactive session holds the
seat: it dispatches the seats, and the user approves the planner's
acceptance changes and merges (`run.md § Seats`). `Supervisor: AI` - a
supervising session dispatches, verifies and merges within the bounds
below, and the user approves acceptance changes and answers the
always-ask list (`run.md § Seats`). Both reach the user under either. A
block without the `Supervisor:` line, or no block at all, halts the
run at resolve, naming the missing line; the bounds line alone grants
nothing. The default grant, **batch-scoped
delivery**, carries
work as far as a green MR/PR and holds one decision class:

- deliver a `plan/` branch to a green MR/PR;
- deliver a batch or member branch whose checkpoint report verifies the
  task's acceptance criteria - the approved plan is the decision, the
  supervisor automates its delivery;
- deliver a task-scoped run's branch, where `finish.md § 1`'s verify
  set stands in for the checkpoint report, and its absence stops the
  delivery as a missing report does;
- queued judgment calls at implementation level, each recorded in the
  report's supervisor-decisions section; an acceptance-level question
  instead goes to the **user** under either mode (`run.md § Seats`,
  `§ Question resolution`).

**The grant includes the merge.** The seat this declaration names
takes `finish.md § 3`'s decision, merge or discard, on every MR/PR:
under `Supervisor: human` the user, under `Supervisor: AI` the
supervisor on a green in-class MR/PR, its merge carrying the
supervision signature below; everything outside the bound - and
everything on the always-ask list - goes to the user. The
implementer/supervisor seam stays: the doer never verifies its own
delivery.

The decision split: implementation-level is code shape, naming, test
details, finding triage within the plan's stated behavior;
design-level is component boundaries, schemas, API shapes,
`DESIGN.md`-level structure, acceptance text. A call the split cannot
classify escalates.

Always asked of the user, under any grant: releases; changes to
`CLAUDE.md`, `rules/`, `skills/`, `hooks/`, `agents/`, `scripts/`,
`settings*.json`, `.mcp.json` or CI configuration - except a
`CLAUDE.md` change confined to the `§ Layout` declaration lines this
file defines; customer data or disclosure;
off-plan work; history rewrites; red gates; design and architectural
decisions.
Host gates (protected trunk, required checks) stay the hard floor for
every seat - no admin merges.

Operating instructions beyond authority - project quirks, escalation
additions, never-touch areas - live in the optional
`.claude/supervisor.md` the declaration references; authority never
moves there.

**Supervision signature.** Supervision is recorded as metadata in two
places and never as prose. Every merge of supervised work carries a
`supervised` label plus a merge comment naming the bound applied and the
seat that applied it. And
where a host exists to run supervised delivery, every commit made on it
carries the mode in its committer field: the author is the human whose
work it is, and `committer.name` says how it was applied, as
`<hostname> (supervised)`, the value `scripts/worker-credentials.sh`
sets on the worker host. git honours
`committer.*` independently of `user.*`, so `git log --author`,
shortlog and blame keep answering about the human.

The label answers at the MR/PR, the committer at any commit reached
later from blame. No commit message, title or body mentions
supervision: `git-workflow.md § MR/PR messages` governs prose and is
unchanged by supervision.

## Declared paths

A project declares its key paths in a `## Layout` section directly
after `## Supervision`, or directly after `## Agent toolchain` where
the project has no `## Supervision`, so the declaration blocks stay
contiguous. Rules and seat prompts name these paths by the
placeholders below; the Tier-1 checks and the session-brief hook read
the line:

```
- Docs: docs/
- Plans: dev/plans/
- Layout: .claude/LAYOUT.md
```

Those values are the defaults and this block is their one home: a
rule names a declared path by its placeholder, and a script that reads
the declaration carries its default once, as the fallback of the read.
Values are repository-relative, a directory with a trailing slash. A
missing line, or no block at all, means that key's default - unlike
`Supervisor:`, an absent declaration never halts a run, so a project
that has not declared keeps working on the defaults. A `Session:`
line, the retired session tree's, is read by nothing, so a project
still declaring it keeps working.

- **`Docs:`** the project's one documentation directory, internal and
  external audiences under one contract (`layout.md § Docs`); the
  default for a new project, and a project keeps the home it has.
- **`Plans:`** the planning tree - `ROADMAP.md`, the per-initiative
  `R<NNN>-<slug>/` directories and `archive/` (`plan.md § Where
  things live`).
- **`Layout:`** the project's layout file, holding the repository's
  actual tree; seeded from the canonical structure `layout.md` holds,
  project-owned and untouched by a tools refresh.

A rule names a declared path by its placeholder - `<docs>`, `<plans>`,
`<layout>` - bare in prose, the slash only before a child
(`<docs>/index.md`) or on a tree's node line (`<plans>/`). The
structure inside a declared root is the canonical structure's and stays
literal, so `<plans>/R<NNN>-<slug>/tasks.md` and `<docs>/references/`
read as before with the root resolved here.

`extended-docs:` is retired. One documentation directory per project,
so a second docs path has no key: the home a project keeps is its
`Docs:` value.
