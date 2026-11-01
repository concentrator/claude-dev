# Git workflow

**Terminology** - a change request is a **PR** on GitHub, an **MR** on
GitLab; before git init, default to PR. One term per repo, per its
host. Host-neutral docs reused across repos (skills, shared
rules) write the dual form **MR/PR**; the agent resolves it to the active
repo's term per its host.

**Declared commands** - the host and its commands come from
`CLAUDE.md § Agent toolchain` (`companions/declarations.md § Declared
commands`).

## Trunk

- `main` is the single trunk: protected and always releasable. No other
  long-lived branches.
- Every change reaches `main` through a short-lived branch and a
  **CI-gated MR/PR**. Never push to `main`; never merge to `main` locally.
- Every change, VIBE or DEV, cuts its working branch before its first edit
  to a tracked path, never after edits made on `main`.
- **Bootstrap exception:** the single initial commit that *creates* `main`
  in a new repo, before protection is set, is the one permitted direct
  commit (`start.md`); every commit after it goes via a branch + CI-gated
  MR/PR. A repository whose `main` already exists has no such commit:
  `start.md` delivers its scaffold on a branch.
- Branch name `<prefix>/<slug>`, kebab-case, slug ≤ 20 chars. Prefix ∈
  {feat, fix, refactor, release, doc, test, mnt, plan, batch}:
  - `feat` / `fix` / `refactor` / `release` - code, matching the change
    type.
  - `doc` - documentation and operative prose (README, CHANGELOG,
    comments, `rules/`, `skills/`, `CLAUDE.md`); not planning artifacts.
  - `batch` - a batch-scoped run's delivery branches (runner-managed; fixed id
    form `batch/R<NNN>-B<NNN>`, exempt from the slug rule).
  - `test` - test additions or changes (automated or manual harness).
  - `mnt` - repo maintenance (CI, scripts, hooks, settings, dependencies).
  - `plan` - planning artifacts (ROADMAP, requirements, tasks, branch
    plans; untracked `.claude/`: `companions/untracked-claude.md`).
    A small change takes no `plan/` branch: its ROADMAP entry,
    requirements, task and plan ride its task's branch (`plan.md
    § Where plans live in git`).
    A planning change a branch discovers about its own task rides that
    branch instead: correcting a wrong item, recording a resolution,
    adding a task the work surfaced. Splitting it out costs a branch, an
    MR/PR and a rebase to move two lines, and the correction reviews
    better next to the work that motivated it. A change reaching beyond
    the branch's own task - another R, the ROADMAP, requirements - still
    takes a `plan/` branch. Who may make the edit is unchanged: plan
    text only on the user's approval, the implementer the checkboxes
    and the task report (`branch-plan.md § Plan edits`, `§ Rails`), and
    an ambiguous item is still a halt (`branch-plan.md § Scope
    discoveries`).
- Slug: code / `doc` / `test` / `mnt` branches carry no id (it lives in
  the plan file + MR/PR); `plan/` branches reference the initiative -
  `plan/r<NNN>-<action>` (R-id, full three digits: `r014`, never `r12`;
  action e.g. `open` / `tasks` / `close`). A task's branch-plan uses the
  task id alone - the prefix already names the action:
  `plan/r<NNN>-t<NNN>` (legacy global ids: `plan/t<NNN>`). Multiple
  initiatives list ids: `plan/r014-r015-tasks`. The weekly audit's
  backlog belongs to no R, so its branch is dated instead:
  `plan/audit-<YYYY-MM-DD>` (`MAINTENANCE.md § Weekly audit`).
- Branches are short-lived and single-owner: merge within a day, two
  days absolute max; keep ≤ 3 active.
- **Merge policy.** Every MR/PR, whatever its prefix, merges after its
  gate is green (§ Merge order), through the declared merge command, by
  the seat the supervision declaration names
  (`companions/declarations.md § Supervisor bounds`; `run.md § Seats`,
  the Merging row). No prefix merges on its own, and no host is armed
  to merge automatically.
- **Merge order.** Run the declared CI wait
  (`companions/toolchain.md § CI wait`) once, in the background (the
  Bash tool's `run_in_background`), and merge on the pass its exit
  notification carries: exit zero when every check passes, non-zero
  when one fails. Nothing outside the wait polls (the REST form polls
  inside it, capped), and a merge called before the pass fails (GitLab
  answers 405). A wait that exits printing `no checks reported` is
  neither pass nor fail, the checks not yet registered: it runs again
  in the background after a short delay, `sleep 30 && <CI wait>`, at
  most 3 times, and a third re-run still printing it goes to the user.
  The declared state
  check (`companions/toolchain.md § State check`) stays the read of
  merged state: an MR/PR it already reports merged is reported as
  merged, never merged again.

## Coherent delivery

Every MR/PR leaves `main` releasable (builds, checks pass, nothing
half-wired). Keep incomplete work coherent without a long-lived branch:

- **Feature flag** - land dormant code, switch on when complete.
- **Branch by abstraction** - migrate behind an abstraction, drop the
  old path last.
- **Small batches** - each MR/PR is one increment, shippable as-is.

The delivery unit - one or more coupled tasks shipped as one MR/PR - is the
**batch** (`branch-plan.md § Agentic execution`).

## Delivery cadence

One branch = one coherent unit of work (a topic or work-session), never
one atomic edit. Don't open or merge an MR/PR per change.

VIBE: cut the working branch first (§ Trunk), apply the change, then wait -
the wait holds back the MR/PR and the merge, never the branch.
Related edits accumulate on the working branch; deliver (open the MR/PR +
merge) at a work boundary - when the user moves to unrelated work or says
to wrap up - confirming the merge first. A work boundary also settles
findings: list any unsaved ones with a proposed destination each and get
approval in one batch (`rules/writing-artifacts.md § One home per finding`). An
edit unrelated to the current branch's topic → flag it and ask whether to
deliver the current branch before starting fresh.

DEV inherits the principle: a branch carries its task/batch, and delivery
timing follows `branch-plan.md § Agentic execution` + `finish`.
Always within the short-lived / ≤ 3 active / merge-within-a-day bounds
above.

**Size is governed by this time bound, not a commit count.**
`branch-plan.md § Size cap` is a subordinate
proxy - the hard limit is merging within the short-lived window with no
big-bang merge (§ Anti-patterns).

## Commit messages

Subject: imperative, ~50 chars / 6-8 words, no semicolons joining
clauses; convey the WHAT, not the HOW. A routine commit is
subject-only.

Body, only when the subject cannot carry the what/why (a no-diff
move, a decision, a constraint): compact prose - no boilerplate, no
file lists, no restating the diff. Routing between the commit,
findings, and task homes: `rules/writing-artifacts.md § One home per finding`.

Examples:
- GOOD: `Fix period chrome over logo`
- GOOD: `Collapse multi-xxl into multi with dense modifier`
- GOOD, a body earning its place:

      Drop the local settings tier

      The durable rules move to the tracked project tier. The local
      file is gitignored, so its deletion leaves no diff.

- BAD: `Fix period chrome shadowing the logo; anchor via .container::before`
- BAD: `Add slide--st03-multi--dense modifier toggled by tenant count for 9+
  tenants`

## MR/PR messages

**Title** - commit-subject style (imperative, ~50 chars, WHAT not how).
**Body** - a short summary (what changed + why) + a test plan: the
checks that matter to verify (manual / non-obvious), not a paste of CI
output; the declared full tier is one line - CI reports the detail.
Scannable, not a wall of text.

- No "Generated with…" line (`dev-instructions.md § Writing`).
- Audience visibility per `dev-instructions.md § Audience visibility`; link
  issues only if openable.

## Releases - tag-on-trunk

`main` is always releasable; a release tags `main` at the release commit
with an annotated semver tag (`git tag -a vX.Y.Z -m "X.Y.Z"`), pushed
explicitly (`git push origin vX.Y.Z`). No release branch - fixes roll
forward on `main`.

## Enforcement

`main` protection is enforced by the host (require MR/PR, require passing
status checks, require up-to-date branch, restrict direct push) plus
CI; a local pre-push hook gives fast feedback but is advisory and
bypassable - never the gate. Host-specific setup lives with the
project's CI infra.

## Anti-patterns

No code freezes; no "unmerge" to back out not-ready work; no fixing on a
release branch then down-merging; no big-bang merges; integrate at least
daily.
