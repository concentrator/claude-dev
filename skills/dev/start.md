# Starting a Project

One-time setup for a new project (existing codebase → `migrate`).
A repository whose `main` already exists, one created on the host,
say, cuts `mnt/dev-scaffold` from `main` before § 1's first write.
Bootstrap, delivery and protection mechanics live in § 5 Commit.

## 1. Requirements

The user supplies a description; ask 1–3 clarifying questions, create
`.claude/` if absent, then write `.claude/REQUIREMENTS.md` per
`templates.md § Foundational` and **block on user approval**
(`approved:` gate as `migrate.md § 2`). Seed file not committed;
`REQUIREMENTS.md` is the spec.

## 2. Design

As `migrate.md § 3` (architecture and design decisions, from the
user's description rather than existing code).

## 3. Scaffold

Baseline files (`layout.md § Baseline files`):
- `/init` → project `CLAUDE.md` incl. `## Conventions` and `## Agent
  toolchain`, spec per `migrate.md § 4`.
- `README.md` (verify or stub).
- `.gitignore` / `.env.example` - seed from the `companions/*.template`
  files; contents per `layout.md § Baseline files`; the `.env` rule and
  the guard that enforces it: `companions/secrets.md`.
- `<plans>` with `ROADMAP.md`.
- Toolset for no-global contributors: per `migrate.md § 5`.

Full config + artifacts layout and baseline set: `layout.md`.

Ask through the AskUserQuestion tool: **release routine?** Record
`release-routine:` in `CLAUDE.md § Conventions`. If yes: `CHANGELOG.md`
seeded with `# Changelog` over an empty `## [Unreleased]`; versioning
(default `vX.Y.Z`); `<plans>/release-v0.1.0.md`. Ask about external
publishing the same way; record `publish-external:`. If
external, override `release` at `<project>/.claude/skills/release/SKILL.md`.

Ask through the AskUserQuestion tool: **comment convention?**, "match
surrounding code" the default option. Record `comments:` in `CLAUDE.md
§ Conventions`; the project's code follows it from the first file
(`rules/code-comments.md`).

Write `## Layout` after `## Agent toolchain` with the defaults
(`companions/declarations.md § Declared paths`) and seed `<layout>`
from `layout.md § Layout file`.

If the project will keep `<docs>` feature docs (`layout.md § Docs`),
record a one-line pointer to `<docs>/index.md` in `§ Conventions`.

## 4. Quality infrastructure

Set up the `migrate.md § 5` baseline (lint + smoke test + CI on every
MR/PR; deferral key included), asking before each item. Offer the
shipped Tier-1 checks `install-dev.sh --project` placed under
`.claude/scripts/` (checks in `ci/`, self-tests in `test/`), wired
into that CI; the batch-tags gate enforces via a local pre-push
hook - its CI run only reports a skip. Document run commands in
`CLAUDE.md`, the wait on the CI just wired as the `CI wait:` line of
`§ Agent toolchain` (`companions/declarations.md § Declared commands`).
An `install-dev.sh --project` install into a git repo appended the
plan-text gate (`check-plan-text.sh`), then the code-size gate
(`check-code-size.sh`), to the `Test (fast):` line, else the `Test:`
line, in whichever of the root `CLAUDE.md` and `.claude/CLAUDE.md` holds
it, or printed the line to add, with both gates and naming both files,
when neither existed, and printed that the project's CI must run the fast
tier: wire the CI to run the fast tier. It appended each gate only where
the line did not name it yet. A `Test (fast):` or `Test:` line written
here, after the install, lacks the gates: end it with them as the
install's printed line shows, or re-run the install to append them. A
global install into `~/.claude` or a non-git project gets no append and
no notice.

## 5. Commit

The initial commit (requirements + design + scaffold + quality config)
creates `main` - the bootstrap exception (`git-workflow.md § Trunk`;
untracked mode deltas: `companions/untracked-claude.md`). Where `main`
already exists, the same commit lands on `mnt/dev-scaffold` instead,
delivered by MR/PR as `migrate.md § 8` does, with no bootstrap
exception. Once the scaffold is on `main`, by either route,
protect `main` on the host - require MR/PR + passing checks, restrict
direct push (`gh`/`glab`; `git-workflow.md § Trunk`, `§ Enforcement`),
TBD-shaped from commit one; thereafter all work lands via a branch + MR/PR.

## 6. Next

Propose `/dev plan R` to shape the first initiative. Do not auto-execute.
