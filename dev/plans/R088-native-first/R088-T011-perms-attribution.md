---
task: R088-T011
type: mnt
mode: normal
---

- [ ] A `CLAUDE.local.md` Edit or Write asks for approval as a `CLAUDE.md`
  one does: the user tier's `permissions.ask` gains
  `Edit(//**/CLAUDE.local.md)`, and `MAINTENANCE.md § Repair` names it among
  the governed files. Approach: the user's settings edit lands before the
  commit, no seat editing the settings surface (`run.md § Seats`); then the
  § Repair sentence. `rules/claude-md.md § Approval` already reads the rule.
- [ ] The CI-wait retry's `sleep 30 && <CI wait>` runs promptless: the
  permission template allows `Bash(sleep:*)`, its source `git-workflow.md
  § Merge policy`'s retry. Approach: `auto-permissions.template.json`, then
  its row in `seat-permissions.md § Bash prefix set`; this repository's
  pre-flight then reports the rule missing until the user's `--apply`.
- [ ] Under `--runner-mode auto` a tier's `Bash(*)`, which auto drops, covers
  no declared rule, so a rule it alone carried reports `missing`, in any
  tier. Approach: `covers` or `tier_of` in `preflight-permissions.sh`, kept
  within the 300-line cap `check-code-size.sh` holds it at; a case beside
  case 6 of its test; a clause in `seat-permissions.md § What enforces what`.
- [ ] The install writes `attribution` with `commit` and `pr` empty and
  `sessionUrl` false, each key only where the target lacks it, so a user's
  own value stays; global and project installs alike, `dev-instructions.md`
  shipping to both. Approach: an `edit_settings` call in `install-dev.sh`
  § 3, then `install-dev-settings.test.sh`, its keeps-its-bytes case included.
- [ ] A `git push` whose outgoing commits, those on no remote-tracking ref,
  carry a `Claude-Session` trailer is denied before it runs, the reason
  naming the commit and `dev-instructions.md § Writing`. Approach: the push
  rules of `hooks/dev-branch-guard.sh`, then a test beside
  `dev-push-guard.test.sh`.
- [ ] Each `autoMode` soft_deny entry names a trigger the classifier sees in
  the action - the command, its arguments, the path written - and judges no
  merge by an MR/PR diff the transcript does not show. Approach: the
  template, `seat-permissions.md § Auto-mode template`, `declarations.md
  § Supervisor bounds` where the mirror moves; the user loads the entries
  into the user tier, and `claude auto-mode critique` finds none on them.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  delete the `### R088-T011` backlog lines, mark the task `[x]` in the R's
  `tasks.md` plus any release-plan entry, commit, the resolved task report
  included. (Batch members: the task mark rides the batch branch.)
