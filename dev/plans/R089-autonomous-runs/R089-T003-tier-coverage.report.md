# R089-T003 report

## Claims
- Item 1 (source): Under `auto`, a `Supervisor: AI` runner's merge needs an
  allow rule for the declared merge command in a settings tier the session
  reads, the rule `toolchain.md § Permission carve-out` shows.
  Source: `skills/dev/companions/toolchain.md § Permission carve-out for
   the checkpoint push`, its note on the merge under either pattern
   (the `Bash(gh pr merge:*)` rule the grant needs, § Merge's
   `Bash(gh *--admin*)` deny added by hand); `docs/reports/dev-dogfood-report.md § Permission
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
  Source: `skills/dev/start.md § 4`, its closing paragraph (no settings
   file written; `.claude/settings.json`'s Bash rules and, under
   `Supervisor: AI`, the `autoMode` block printed for the user) and
   § 3's `.claude/settings.json` bullet; `skills/dev/layout.md
   § Creation policy`, the file written by the user at scaffold;
   `docs/reports/dev-dogfood-report.md § Permission stops`, row 5 (the
   "Self-Modification" refusal); `skills/dev/companions/seat-permissions.md
   § Bash prefix set` and `§ Auto-mode template` (Claude Code reads
   `autoMode` from no project tier)

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
- Item 2: the print sits at the end of `start.md § 4` rather than in
  § 3, § 3 carrying a `.claude/settings.json` bullet pointing to it:
  the rules derive from `§ Agent toolchain`, whose CI wait line and the
  `Test (fast):` line's gates (stop 8's `check-plan-text.sh`) § 4
  settles, so a print in § 3 would miss them. Stop 3's `wc` and `ls`
  are the template's `Bash(` entries the print cites. `layout.md
  § Creation policy` moves `.claude/settings.json` from required at
  scaffold to a line of its own, written by the user. No rule for
  `context-cost.py`. Result: the fast tier passes.
- Review 1: the merge note is a bold-led paragraph after pattern 2,
  inside the carve-out section. With the merge rule out of carve-out 1,
  `declarations.md § Supervisor bounds`, `seat-permissions.md
  § Auto-mode template` and README cite the carve-out without its "1",
  and the first `## Claims` entry's source names the note. Result: the
  fast tier, `preflight-permissions-toolchain.test.sh` and
  `toolchain-forms.test.sh` pass.
- Review 2: the one host is GitHub: `Bash(gh pr create:*)` replaces
  `Bash(glab mr create:*)`, matching § Push + MR/PR's primary form and
  the note's `gh pr merge` rule. `start.md § 4` leaves the change-request
  rule to the declared commands' rules too, carve-out 1 contributing its
  push strings and deny pair alone. Result: the fast tier passes.
- Review 3: the row keeps its record of the refusal and the review
  session's merge; only the backlog clause changes. Result: the fast
  tier passes.

## Review

- [x] Item 1: the carve-out's pattern-1 block carries `Bash(gh pr merge:*)`
  and `Bash(gh *--admin*)`, though the pre-flight requires both under
  either pattern; the deny then contradicts "the pair" of
  `seat-permissions.md § Mode-independent set` and the push-only
  sentence after it, and pattern 2 still reads "Zero config" while a
  `gh pr merge` Merge line fails its pre-flight on a deny `--apply`
  cannot write (Critical) - skills/dev/companions/toolchain.md:149
  Evidence: observed `preflight-permissions.sh:138-141`, `:268-271`,
  `:296`; `seat-permissions.md:81-83`; toolchain.md:153, toolchain.md:176;
  a second verifier confirmed
- [x] Item 2: the carve-out JSON pairs GitLab's `glab mr create` with
  GitHub's `gh pr merge` and deny, and `start.md § 4` prints carve-out 1
  as written beside the declared commands' rules, so a project gets the
  other host's rule and a GitHub one the merge rule twice (Important) -
  skills/dev/start.md:86
  Evidence: observed toolchain.md:147-150, start.md:85-88
- [x] Item 1: the dogfooding pitfalls' "Merges refused" row still names
  the merge allow rule as toolset backlog, which this branch ships
  (Important) - skills/dogfooding/companions/pitfalls.md:13
  Evidence: observed pitfalls.md:13, toolchain.md § Permission carve-out
- [x] Item 1: `seat-permissions.md § Auto-mode template` counts the
  `--admin` deny among "the host's gates", while it is a settings-tier
  rule (Important) - skills/dev/companions/seat-permissions.md:411
  Evidence: observed seat-permissions.md:411-413, seat-permissions.md:236-242
- [x] Item 1: `toolchain.md` states the `--admin` deny beside the
  `gh pr merge` rule twice, in § Merge and the carve-out (Suggestion) -
  skills/dev/companions/toolchain.md:166
  Evidence: observed toolchain.md:89-90, toolchain.md:166-168
- [x] Item 1: `seat-permissions.md` and `README.md` paraphrase what
  `run.md § Merge or ask` does, which it warns a partial copy misleads
  (Suggestion) - skills/dev/companions/seat-permissions.md:409
  Evidence: observed seat-permissions.md:409-410, README.md:106-108,
  `run.md § Merge or ask`
