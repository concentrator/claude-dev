---
task: R089-T003
type: mnt
mode: normal
---

- [x] Under `auto` a `Supervisor: AI` runner's merge passes: the carve-out
  ships an allow rule for the declared merge command, which the AI grant
  needs, and the always-ask merges that rule hides from the classifier stay
  with `run.md § Merge or ask` and the host's gates. Approach: carve-out 1,
  `declarations.md § Supervisor bounds`, `seat-permissions.md § Auto-mode
  template`; template unchanged, the pre-flight deriving the `Merge:` rule.
- [ ] `/dev start` writes no settings file and prints each with its content:
  for `.claude/settings.json` the Bash rules the pre-flight declares, carve-out
  1 included (the dogfood report's stops 3, 5, 8); under `Supervisor: AI` the
  `autoMode` entries for `~/.claude/settings.json`. Approach: `start.md § 3`,
  `layout.md § Creation policy`, citing the templates and carve-out, not
  copying them; no rule for `context-cost.py`, which no flow step runs.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included. (Batch members: the task
  mark rides the batch branch.)

## Claims

- Item 1 (source): Under `auto`, a `Supervisor: AI` runner's merge needs an
  allow rule for the declared merge command in a settings tier the session
  reads, the rule `toolchain.md § Permission carve-out` shows.
- Item 1 (source): A merge that allow rule matches does not reach the
  classifier, so `run.md § Merge or ask` and the host's required checks hold
  the always-ask merges.
- Item 2 (source): `/dev start` writes no settings file: it prints the
  permission rules for `.claude/settings.json` and, under `Supervisor: AI`,
  the `autoMode` entries for `~/.claude/settings.json`, each with its
  content, for the user to write.

## Proven

- Under `auto` the classifier refuses an agent's merge no allow rule covers
  as "Merge Without Review", after an independent review and green CI:
  `docs/reports/dev-dogfood-report.md § Permission stops`, rows 6 and 7
- Under `auto` the classifier refuses a session's write of
  `.claude/settings.json` as "Self-Modification":
  `docs/reports/dev-dogfood-report.md § Permission stops`, row 5
- The pre-flight reads the declared `Merge:` line into its Bash prefix set:
  `scripts/test/preflight-permissions-toolchain.test.sh`
- `auto` keeps narrow allow rules and sends only a command no rule matches to
  its classifier: `skills/dev/companions/seat-permissions.md § What enforces
  what`
