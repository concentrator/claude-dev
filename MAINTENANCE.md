# Maintenance

Keeps `.claude/` and the project root clean and healthy. Two parts: the
**Tier-2 AI review** gates each change into `main` (per-PR); the
**Routine** is the time-based cleanup + repair sweep. The Routine
section is generic; `install-dev.sh --project` seeds its hygiene subset
into an adopter's `.claude/MAINTENANCE.md` when the section is absent,
project-owned afterward. The **This environment** section holds targets
unique to this repo, the weekly audit and its backlog among them.

## Tier-2 AI review

A mandatory compliance review for this repository, complementing the Tier-1
mechanical CI checks in `scripts/ci/`. At branch close, before delivery,
review the diff against the rule set and confirm the concerns below:

- **Compliance** - what the diff adds obeys its file's governing rule
  (`CLAUDE.md` and `dev-instructions.md` per `rules/claude-md.md`;
  `SKILL.md` per `rules/skills.md`;
  plans per `skills/dev/plan.md`).
- **Cross-file integrity** - references resolve; no rule duplicated
  across files (read maximally: any echo of a rule's text is a
  restatement), so a concern names the rule and cites its owning
  document (`rules/claude-md.md § Size and structure`, "No
  duplication"); `LAYOUT.md` matches the tree.
- **Cleanup** - no stray scratch or transient content, and no dead
  prose: every rule, instruction, or sentence the diff adds or touches
  passes three gates - accurate and sensible in context; valuable in a
  real scenario; behavior would change if it were removed. Fail any →
  cut it and propose the fix (content tests: `rules/claude-md.md
  § Content`).
- **Reference freshness** - no dead paths; no expired time-bound
  references. Mark a time-bound reference `<!-- expires: YYYY-MM-DD -->`;
  `scripts/ci/check-references.sh` fails once the date is past.
- **Doc sync** - a change that alters a documented surface updates the
  doc documenting it, in the same branch. The concern covers docs the
  diff does not touch: staleness a change induces elsewhere has no other
  owner, since every other concern reads only changed files. A project
  may keep a table of path globs, each row naming the docs that adding,
  removing or renaming a matching path must update (here: § This
  environment › Doc-sync pairs); the concern judges against it and the
  project's own docs.
- **Writing** - changed prose follows `writing.md` and
  `rules/writing-artifacts.md`.

## Routine

Run on the cadence below, or on demand. For each target: detect → report
→ repair. Never silently delete something you didn't create; surface
contradictions instead of acting on them.

### Targets and thresholds

Initial defaults - tune per project.

| Target | Check | Cadence / threshold |
|---|---|---|
| Transcripts | retention | `cleanupPeriodDays` (settings) |
| the `Plans:` tree (`§ Layout` of `CLAUDE.md` or `.claude/CLAUDE.md`) | orphaned or closed plan, findings, requirements & batch files; empty `R<NNN>-<slug>` dirs | monthly |
| `.claude/settings.json` + any regrown `settings.local.json` | allow-list mess: one-off / dead / overlapping rules; local entries a tracked tier already carries | weekly |
| skills/ | dead, unused, broken, or duplicate skills | monthly |
| rules/, CLAUDE.md, foundational docs & README | stale paths / dead references | on edit + monthly |
| repo root & `.claude/` | stray temp / build artifacts | weekly |
| sizes | caps per `claude-md.md § Size and structure` / `skills.md § Size` | on edit |
| file counts | flag unexpected growth in the `Plans:` tree, skills/ | monthly |

### Repair

Governed files ask before an Edit or Write: the `permissions.ask` list
of `~/.claude/settings.json` holds every `CLAUDE.md`,
`dev-instructions.md`, `SKILL.md`, `.claude/rules/` file and
`.claude/settings*.json`, and this clone's `rules/` by its absolute
path. A shell edit to one is proposed and awaits approval
(`claude-md.md` / `skills.md` § Approval). Repairs:

- Broken JSON / invalid settings → fix or revert.
- Dead reference (missing skill, renamed path) → update or remove.
- Findings/plan files for merged work → promote their durable facts;
  the files archive with their initiative, never per task
  (`skills/dev/plan.md § Archival`).
- Duplicate rule across files → single-home (`claude-md.md § Size and
  structure`).

### Generalize allow rules

Accepted permission prompts accumulate as verbatim one-offs; the list
rots and prompts keep rising for near-identical commands. Weekly, per
settings file (`settings.json` global, `.claude/settings.json` project
tier, any regrown `settings.local.json` per machine):

1. Group entries by command; collapse variants into one prefix rule
   (`Bash(go test -v ...)`, `Bash(go vet ...)` → `Bash(go:*)`).
   Generalize only the prefix actually recurring - not `Bash(*)`.
2. Drop spent one-offs: exact commands with literal paths, session
   scratch (`/tmp/*.sh`), finished migrations/renames.
3. Drop entries embedding secrets/tokens - always; rotate if leaked.
4. Drop rules that defeat the allowlist (`Bash(bash *)`,
   `Bash(env)`-style secret dumps) - re-approve narrowly instead.
5. Rule covered by a broader tier (global ⊃ project ⊃ local) → keep
   the broad one, delete the shadowed.
6. Recurring prompts the list misses → `/fewer-permission-prompts`
   scans transcripts and proposes additions; merge its output through
   steps 1–5.
7. Validate (`jq -e . <file>`); never commit a tracked settings file
   containing credentials.

## This environment (repo-specific)

Targets beyond the generic routine:

- Skill usage audit (monthly): read `~/.claude/skill_invocations.jsonl`
  (written by the `PostToolUse`/`Skill` hook in
  `~/.claude/settings.json`). A skill with
  zero invocations over the period and no inbound reference from
  `dev-instructions.md` / rules / other skills → flag for triage (wire in, accept
  as description-triggered, or remove). Truncate the log after review.
- Pre-push hook: a tracked `.githooks/pre-push` runs the Tier-1 gate
  (`scripts/ci/run-all.sh`) locally - advisory, bypass with
  `git push --no-verify`. Enable once per clone:
  `git config core.hooksPath .githooks`.
- Verify no skill or rule references removed scripts/log files.
- Confirm foundational files stay at the repo root (not nested
  `.claude/`), per `DESIGN.md § Self-hosting layout`.

### Doc-sync pairs

Targets for the Doc sync concern (§ Tier-2 AI review). A branch that
adds, removes or renames a tracked path a row's glob matches updates
each file the row names, a renamed path answering to the rows of both
its old and new paths. A glob matches the whole path, `*` standing for
any run of characters but `/`. A row names a file only if that file
lists each path the glob matches.

| Path | Update |
|---|---|
| `*` | `LAYOUT.md`, `README.md § Contents` |
| `.claude/*` | `LAYOUT.md`, `README.md § Contents` |
| `.githooks/*` | `LAYOUT.md` |
| `.github/workflows/*` | `LAYOUT.md` |
| `hooks/*` | `LAYOUT.md` |
| `rules/*` | `LAYOUT.md` |
| `scripts/*` | `LAYOUT.md` |
| `scripts/ci/check-*.sh` | `scripts/ci/run-all.sh`, `DESIGN.md § Self-enforcement` |
| `skills/*/SKILL.md` | `LAYOUT.md` |
| `skills/dev/*.md` | `skills/dev/SKILL.md` |

The concern also judges these pairs, which no row expresses:

- A file moved or renamed: every inbound reference (grep the tracked
  tree).
- A top-level directory added or removed: `LAYOUT.md`,
  `README.md § Contents`.
- A `/dev` command added, renamed or removed: `skills/dev/SKILL.md
  § Surface`, `README.md § Workflow`.
- What `install-dev.sh` copies or registers: `README.md § Installing
  the toolset elsewhere`, and `scripts/test/install-dev.test.sh`,
  `install-dev-minimal.test.sh` and `install-dev-manifest.test.sh`, which
  assert the copied sets.
- What a `hooks/` guard blocks: `DESIGN.md § Self-enforcement`.
- The planning layout or an id or naming convention: `README.md`,
  `REQUIREMENTS.md § Planning discipline`, `DESIGN.md`, and every
  `skills/dev/` file stating the convention (`plan.md`, `layout.md`,
  `branch-plan.md`, `write-plan.md`, `finish.md`, `templates.md`).

### Weekly audit

A weekly cloud routine, created with `/schedule`, checks this repository
against Claude Code's current defaults and documentation and proposes
each new finding as a § Backlog line. Its prompt:

```text
Audit this repository - the DEV toolset, which its installer copies into
~/.claude - against Claude Code's current defaults and documentation.

1. Read Claude Code's current documentation and release notes for the
   settings, hook events, tools, permission modes, slash commands and
   default behaviors this repository uses or replaces.
2. Read the repository: dev-instructions.md, writing.md,
   .claude/settings.json, DESIGN.md, rules/, skills/, agents/, hooks/
   and scripts/.
3. A finding is a rule, skill, hook, script or setting that overrides a
   Claude Code default, rebuilds a native feature, or names a setting,
   event, tool or behavior the documentation no longer describes. Each
   one cites its repository path and the documentation page or release
   note it rests on.
4. Drop a finding that MAINTENANCE.md § Backlog already lists, and one
   a home named in rules/writing-artifacts.md § One home per finding
   already settles.
5. With no finding left, stop: no branch, no commit, no PR.
6. Otherwise cut plan/audit-<YYYY-MM-DD> from main, append one line per
   finding to MAINTENANCE.md § Backlog in its form, commit, push and
   open a PR listing the findings with their sources, the commit and
   PR text per skills/dev/git-workflow.md § Commit messages and § MR/PR
   messages. Do not merge it.
```

### Backlog

Findings of the weekly audit not yet taken into a plan, one line each:
`- <path>: <finding> (<documentation source>)`.
