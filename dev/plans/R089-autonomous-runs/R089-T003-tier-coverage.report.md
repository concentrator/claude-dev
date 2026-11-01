# R089-T003 report

## Claims
- Item 1 (source): Under `auto`, a `Supervisor: AI` runner's merge needs an
  allow rule for the declared merge command in a settings tier the session
  reads, the rule `toolchain.md § Permission carve-out` shows.
  Source: `skills/dev/companions/toolchain.md § Permission carve-out for
   the checkpoint push` 1, its `Bash(gh pr merge:*)` allow entry and
   `Bash(gh *--admin*)` deny, and the paragraph naming the merge rule
   the grant needs; `docs/reports/dev-dogfood-report.md § Permission
   stops`, rows 6 and 7 (the "Merge Without Review" refusal of a merge
   no rule covered); `scripts/preflight-permissions.sh`
   `toolchain_rules` (the `Merge:` line up to its first placeholder)
   and the `check_deny` beside a `Bash(gh pr merge` rule;
   `skills/dev/companions/declarations.md § Supervisor bounds`, "The
   grant includes the merge"
- Item 1 (source): A merge that allow rule matches does not reach the
  classifier, so `run.md § Merge or ask` and the host's required checks hold
  the always-ask merges.
  Source: `skills/dev/companions/seat-permissions.md § What enforces
   what` (auto keeps narrow allow rules and routes only a command no
   rule matches to its classifier) and `§ Auto-mode template`, its
   closing paragraph; `skills/dev/companions/auto-mode.template.json`,
   the soft_deny entries DEV Release, DEV Instruction Change and DEV
   Red Gate, each naming a merge; `skills/dev/run.md § Merge or ask`
   (the class named before any merge, everything else asked of the
   user); `skills/dev/companions/declarations.md § Supervisor bounds`
   (the always-ask list, host gates as the hard floor)
- Item 2 (source): `/dev start` writes no settings file: it prints the
  permission rules for `.claude/settings.json` and, under `Supervisor: AI`,
  the `autoMode` entries for `~/.claude/settings.json`, each with its
  content, for the user to write.
  Source:

## Implementer
### Divergences
- Item 1: carve-out 1's JSON gains `Bash(gh pr merge:*)` in its allow
  and `Bash(gh *--admin*)` in its deny, R089-T004 having made that deny
  required beside a `gh pr merge` rule; its prose names the rule as the
  declared merge command's, a REST merge carrying its script's path
  with no deny. The fact that an uncovered merge is refused as "Merge
  Without Review" lives in carve-out 1; `declarations.md § Supervisor
  bounds` states the need in one sentence and cites it, and
  `seat-permissions.md § Auto-mode template` holds which soft_deny
  merges the rule hides and what holds them. The template, the
  pre-flight and its tests are unchanged: the pre-flight already
  derives the `Merge:` rule and its deny. Result: the fast tier
  passes.

## Review
