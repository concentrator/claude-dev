---
task: R088-T012
type: mnt
mode: normal
---

- [ ] The plan-text gate accepts an MR/PR number, `#545` say, in ROADMAP
  entries and `tasks.md`, as the durable-id rule allows, and still rejects
  it in `requirements.md`, which `templates.md` keeps free of PR refs.
  Approach: the `#NNN` check of `check-plan-text.sh` and its header, the
  accept and expect cases in its test, then the cite-by-id sentence of
  `templates.md § Per-initiative tasks.md`.
- [ ] The full tier runs once per change, as CI on its MR/PR: a close or a
  batch close runs no local `Test (full)`, and a project with no `CI wait:`
  line runs it locally once at close instead. Approach: `finish.md § 1` and
  § 3 step 1, `batch.md § Per-branch close` and § Batch close 3,
  `declarations.md § Declared commands`, `branch-plan.md § Commit cadence`
  1, then the full-tier fields of `report-template.md`.
- [ ] (sonnet) The remaining plain-text asks go through the AskUserQuestion
  tool, as `brainstorm.md` step 3 does: brainstorm's approach choice,
  start's clarifying and quality-baseline questions, finish's merge
  confirmation with no declared host. Approach: `brainstorm.md` step 4,
  `start.md § 1` and § 4, the opening of `finish.md § 4`; sonnet, as each
  site is named and no design choice is left.
- [ ] (sonnet) The dispatching-parallel-agents skill's examples dispatch with
  `Agent(...)`, the tool's name, not `Task(...)`. Approach: the three calls
  under § 2 of `skills/dispatching-parallel-agents/SKILL.md`; sonnet, as the
  file and lines are named and nothing is left to decide.
- [ ] `batch.md § Batch close` 2 names where a judgment call queues: a
  `## Review` entry in the task report of the member whose code it concerns,
  as `run.md § Close` 2 queues its own, the batch report listing it and
  `run.md § Merge or ask` reading it back. Approach: that step alone.
- [ ] The README states its enumerations as lists or table rows, never
  inline comma-runs (`documentation.md § Formatting`): its opening and the
  § Contents rows that run one, `.claude/settings.json`, `.github/`,
  `MAINTENANCE.md` and `dev/` among them. Approach: `README.md` alone, each
  row's facts kept; a cell too long for a list moves its detail to a list
  under the table.
- [ ] The README says what each PreToolUse guard blocks: the branch guard a
  write, commit or push landing on the default branch, a force push and the
  moves that lose work; the secrets guard secret-shaped content entering a
  tracked file or a commit. Approach: beside the hook table of `README.md
  § Installing the toolset elsewhere`, from each hook's header comment.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  delete the `### R088-T012` backlog block, its `check-doc-sync.sh` line
  included, which R091-T002 settled by deleting that script, commit, the
  resolved task report included. (Batch members: the task mark rides the
  batch branch.)
