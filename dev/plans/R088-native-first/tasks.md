# R088 tasks - Native first

Why: rules that override Claude Code's defaults cost turns, dispatches and tokens a native feature would save.

## Open

- [x] **R088-T001 [mnt]**: simple fixes - align each rule that overrides a native
  default with a setting, a one-line edit or a deletion, and fix the stale
  names the audit found.

- [x] **R088-T002 [mnt]**: compaction without hand-off notes or a ledger, one CI
  wait that notifies pass or fail, explanations in their existing homes,
  review cost under the project's control, and the weekly audit routine.

- [x] **R088-T003 [doc]**: docs rails - a table mapping paths to the doc files a
  change must update, a check that enforces it, and present-tense docs.

- [x] **R088-T004 [mnt]**: two-step planning - requirements and design, then the
  task list with a plan per task; a small change ships in one MR/PR.

- [x] **R088-T005 [mnt]**: permissions on native modes, settings and hooks, with
  the auto-mode classifier configured and the pre-flight cut to what binds.

- [x] **R088-T006 [mnt]**: framework install - files copied onto a machine, the
  user's files and settings never overwritten, the repository no longer the
  user's config directory.

- [ ] **R088-T007 [mnt]**: a saved workflow runs the seats, continuing a seat for
  its follow-ups, and each seat loads only the text its step needs.

- [x] **R088-T008 [mnt]**: the GitHub repository is named `claude-dev`,
  matching its clone, and everything that names it follows.

- [x] **R088-T009 [doc]**: the text gaps `docs/reports/dev-dogfood-report.md`
  found close: release steps, release plan entries, CHANGELOG seed, plan header
  fence, committer value, batch-close fix seat, attribution precedence.

- [ ] **R088-T010 [doc]**: release and migrate text agree - one tag message,
  the release branch, the plan's archive move, release marking, a step that
  writes the release plan; migrate adds `comments:` and `## [Unreleased]`.

- [ ] **R088-T011 [mnt]**: permissions and attribution - rules for
  `CLAUDE.local.md` and the CI-wait `sleep`, the pre-flight under `auto`, the
  `autoMode` entries, a gate on session trailers, the `attribution` setting.

- [ ] **R088-T012 [mnt]**: gates and remaining text - MR/PR numbers in plan
  text, one full test run, asks through AskUserQuestion, `Agent(...)`
  examples, the batch-close queue, the README.

## Backlog

### R088-T010

- `release.md` step 8 tags with `-m "<short>"`, `git-workflow.md § Releases` with `-m "X.Y.Z"`.
- `git-workflow.md § Releases` says "No release branch", while `release.md` step 3 cuts `release/vX.Y.Z`.
- `release.md` step 10 offers the release plan's archive move after the merge, a commit on the default branch.
- `branch-plan.md § Batches` routes release marking to the close-out MR/PR, while `release.md` step 1 has it ride each branch's final commit.
- `/dev plan release` routes to `release.md`, which has no step that writes a release plan.
- `/dev migrate` does not add the `comments:` convention line to an existing project's `CLAUDE.md § Conventions`.
- `/dev migrate` does not add `## [Unreleased]` to an existing project's CHANGELOG.

### R088-T011

- `CLAUDE.local.md` has no `permissions.ask` rule, so its rule keeps a propose-and-wait step.
- No allow rule covers the `sleep` the CI-wait retry runs.
- The pre-flight counts a user-tier `Bash(*)` as covering every declared Bash rule under `auto`, which drops it.
- The `autoMode` soft_deny entries name no visible DEV-run trigger or must-name slot, nor presume an unseen MR diff.
- No gate stops a `Claude-Session` trailer before push.
- The install does not write the `attribution` setting that the no-trailer intent relies on.

### R088-T012

- The durable-id rule allows citing an MR/PR number, but the plan-text gate still rejects `#NNN` in ROADMAP and `tasks.md`.
- The full test tier runs locally right before CI runs it.
- Brainstorm's approach choice, start's clarifying and quality questions, and finish's no-host merge confirmation still ask in plain text, not through AskUserQuestion.
- The dispatching-parallel-agents skill still shows `Task(...)` examples; the tool is Agent.
- `run.md § Batch close` 2 queues judgment calls without naming where.
- The README keeps inline comma-runs the docs gate did not list: its opening and several layout rows.
- The README no longer says what the guards block.

### Unassigned

- No command starts a remote runner, and `supervisor-runbook.md` Variant B omits pulling the host's `~/.claude` first.
