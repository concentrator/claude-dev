---
task: R088-T007
type: mnt
architecture-changing: true
mode: normal
---

- [ ] USER: a throwaway saved workflow shows whether one in
  `~/.claude/workflows/` runs by name with `args`, whether `agent()` with
  `agentType` runs a seat on its definition's tools and model, and whether the
  session continues that seat by SendMessage once the run returns. Approach:
  the runner drafts it, the user runs it here, the runner records the output
  under `## Answers` and marks this; a no on continuing halts the branch.
- [ ] A saved workflow, `workflows/dev-run.js`, holds the run sequence and its
  loop bounds: an implementer seat per open item on its tier, the close review,
  the doc writer, returning to the runner at each step that needs the user or
  git, with the seat's report and the id that continues it. Approach:
  `docs/reports/workflow-seats.md` from item 1's answer, the script and its
  test, then `LAYOUT.md`.
- [ ] An install ships the saved workflows to `<target>/workflows/`, and the
  permission set declares what starting one needs in each mode. Approach:
  `install-dev.sh` and `install-manifest.sh` with the three install tests,
  `README.md § Installing the toolset elsewhere`, then
  `seat-permissions.md`, the permission template and
  `preflight-permissions.sh` with its test.
- [ ] `/dev run` starts `dev-run` for each branch's items and close, the skill's
  instruction being the Workflow tool's opt-in, and `run.md` keeps what the
  script cannot: the user's steps, git between runs, the checkpoint; the loop
  bound is stated in the script alone. Approach: `run.md § Seats`, § Dispatch
  per item and § Close, `batch.md`, `verification-policy.md § Models`, then
  the loop diagram in `supervisor-runbook.md`.
- [ ] An implementer's question or acceptance-changing concern continues that
  seat: the runner sends the answer by SendMessage, no revert and no fresh
  seat, the answer still written to `## Answers`; a tier-up rerun and the
  close fixes, which span items, keep a fresh seat. Approach: `run.md
  § Question resolution`, § Dispatch per item 2, § Checkpoint, `branch-plan.md
  § Session boundary`, § Scope discoveries, `agents/dev-implementer.md`.
- [ ] The docs gate's mismatch list goes by SendMessage to the doc writer that
  wrote the docs, not to a fresh one. Approach: `run.md § Close` 3 and
  § Seats, `agents/dev-doc-writer.md § Inputs`, `documentation.md
  § Verification gate`.
- [ ] A cite of `<file> § <section>` loads that section alone: a line in
  `dev-instructions.md`, which every seat receives, says how, and each seat
  definition cites the sections its steps need, never a whole file. Approach:
  the line (Read's offset and limit from the heading's line, say), the
  whole-file cites in `agents/`, then `branch-plan.md § Session boundary`.
- [ ] `DESIGN.md` says a saved workflow runs the seats and a seat lives until
  its follow-ups are answered. Approach: `§ Git & delivery model`, then
  `§ Invariants` where it names the loop bound.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included. (Batch members: the task
  mark rides the batch branch.)
