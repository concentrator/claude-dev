# Seat permissions

The run's permission set: declared once, split by what enforces it, and
settled before the first dispatch. `run.md § Pre-flight` resolves it
against the settings tiers through `<config>/scripts/preflight-permissions.sh`,
`<config>` being the directory the toolset is installed into: `~/.claude` for
a global install, from a clone of the framework repository, and `.claude`
from the root of a project installed with `--project`.

Every rule here traces to one of four sources: a seat definition under
`agents/`, a dispatch companion under `companions/`, the project's
`CLAUDE.md § Agent toolchain` line, or a `skills/dev/` flow step the
runner runs itself, which is what puts the runner's own commands in the
set with no seat issuing them. An entry naming none of the four is not
carried, and a need that absence turns out to cover comes back through
the pre-flight's report and its `--apply`, never as an untraced entry
here.

Two words read "mode" in this tree. The **permission mode** is the
runner's launch mode (`auto`, `acceptEdits`, `default`); the
**supervisor mode** is the `Supervisor: human | AI` line
(`companions/declarations.md § Supervisor bounds`).

## What enforces what

The set holds only what binds in the run's permission mode: deny rules,
the mode assertion with its never-list, and the allow rules that mode
reads. Under `--permission-mode auto` those are the narrow allow rules:
auto drops the broad ones that grant arbitrary code execution - a
blanket `Bash(*)`, a wildcarded interpreter such as `Bash(python*)`,
package-manager run commands, and every `Agent` and `Monitor` rule -
and routes a command no rule matches to its classifier. A rule set the
mode drops is neither declared nor checked, so the set carries none of
those. The set splits by enforcement rather than by seat.

- The **mode-independent set** binds in every permission mode.
- The **Bash prefix set** binds in every mode as well, auto keeping
  narrow Bash rules - save when the user tier, of the three the one auto
  reads `autoMode` from, sets `autoMode.classifyAllShell: true`, under which
  auto suspends every Bash allow rule. The pre-flight then reports the
  set `dropped (auto)` on one line and checks none of its rules;
  outside auto the switch changes nothing.

Both sets are applyable, and a gap in either stops the run, save a
missing allow rule under `Supervisor: human` (§ Prompt classes).

No declaration makes an autonomous run promptless on its own: a
classifier denial is nondeterministic and a long transcript can fall
back to manual approval, both of them runbook-recorded events
(`companions/supervisor-runbook.md § Failure modes`) rather than gaps in
a declared set.

## Mode-independent set

| Rule | Class | Source |
| --- | --- | --- |
| `Edit(//__PROJECT_DIR__/**)` | Edit-class, the checkout root | the seat definitions carrying an edit tool: `agents/dev-implementer.md`, `agents/dev-planner.md`, `agents/dev-doc-writer.md` |
| `Read(//__HOME__/.claude/skills/**)` | Read outside the checkout | the seat definitions, which send a seat to `skills/dev/...` (`agents/dev-implementer.md`, `agents/dev-planner.md`) |
| `Read(//__HOME__/.claude/rules/**)` | Read outside the checkout | the seat definitions, which send a seat to `rules/writing-artifacts.md` (`agents/dev-planner.md`, `agents/dev-doc-writer.md`) and to `rules/code-comments.md` (`agents/dev-implementer.md`, `agents/code-reviewer.md`) |
| `Read(//tmp/**)`, `Read(//private/tmp/**)`, `Edit(//tmp/**)`, `Edit(//private/tmp/**)` | Read and Edit outside the checkout | `agents/dev-implementer.md § Steps`, its scratch paragraph |
| `WebSearch` | bare tool | `agents/code-reviewer.md`, which holds that tool |
| `WebFetch(domain:<host>)` | WebFetch | a seat's dispatch naming the domain; the class has no default member |
| `Skill(<name>)` | bare tool | a dispatch naming the skill; the implementer holds `Skill` (`agents/dev-implementer.md`) |
| the carve-out pattern's deny set (below) | deny | `companions/toolchain.md § Permission carve-out` |
| the mode assertion (below) | assertion | `companions/supervisor-runbook.md § Modes by seat` |

Never `bypassPermissions`, never `dontAsk`: the first discards deny
rules along with everything else, the second denies rather than asks
(`companions/supervisor-runbook.md § Modes by seat`).

The mode assertion is narrow: `--permission-mode auto` on the runner's
launch command, and each tier's mode key unchanged from its tracked
value. It never asserts that `defaultMode` is absent - the user tier's
`defaultMode: acceptEdits` is an approved standing decision (R056-T002,
archived) - the concern being a mode key drifting after a run has
started.

**The declared push deny** is whichever carve-out pattern's deny set the
tiers are on, a narrowed deny being deliberately weaker than the blanket
one and neither covering the other. Pattern 2 declares
`Bash(git push:*)`; pattern 1 declares the pair
`Bash(git push origin <default>:*)` and `Bash(git push --force:*)`, with
`<default>` the repo's own default branch name.

Pattern 1 declares the checkpoint-push allow block beside that pair -
the push strings `toolchain.md § Permission carve-out` 1 prints, which
is their one home (§ Bash prefix set). They are Bash prefix rules rather
than mode-independent ones, binding wherever that set does
(§ What enforces what). Pattern 2
declares none of them. Its blanket deny beats every allow across all
tiers, so its checkpoint push stays the one manual push per batch that
pattern is, and a declared allow every pattern-2 tier denies would turn
every pattern-2 session into a cannot-apply.

The pattern is read from the tiers, never from a flag or from this text:
off the union of the `deny` sets of every tier the session reads - user,
project and local - because deny beats allow across all tiers
(`toolchain.md § Permission carve-out`) and the tiers can disagree. An
entry is satisfied by its exact string in the `deny` of any one of those
same tiers. One content answers both questions: the tier's working-tree
file, which is what the session's own permission check reads and so what
binds the run. No git state enters either read, so the pattern and the
entries that pattern declares are never read from two different contents
of one file.

- A blanket entry in any of the three makes the session pattern 2, the
  report naming the tier that carries it and that same tier satisfying
  pattern 2's one declared entry. A user tier's `Bash(git push:*)`
  beside a project tier's narrow pair is pattern 2, accepted under
  `Supervisor: human` and cannot-apply under `Supervisor: AI`, the
  project tier's pair notwithstanding.
- A union carrying no blanket entry is pattern 1 whatever it carries of
  the pair - both entries, one, or neither - each entry reported on its
  own line. A union carrying neither is the missing-deny gap.
- The pair's two entries are satisfied from two tiers as readily as from
  one. A pair carried by the local tier alone satisfies pattern 1, which
  is the shape a provisioned worker arrives in.
- Extra deny entries beyond the pattern's are never a gap.

A missing deny is the one gap `--apply` cannot close, the pre-flight
writing no deny rule: the remedy is the missing string added to the
tracked project tier's `deny`, which is where `toolchain.md § Permission
carve-out` puts a project's declaration for the next clone. That file
edit is the whole remedy, with no commit and no branch, so the halted
run waits on nothing that would put a commit on the default branch it is
standing on (`git-workflow.md § Trunk`).

This repository's `.claude/settings.json` carries the pair, so a session
in it is on pattern 1 unless the user tier, `~/.claude/settings.json`,
or the local tier carries a blanket entry.

## HEAD moves and whole-tree discards

What holds a seat off HEAD is a branch in `hooks/dev-branch-guard.sh`,
not a settings deny on `git checkout`, `switch`, `reset`, `restore` or
`stash`: a deny reads none of a command's arguments, so one wide enough
to catch a shape below also stops the flow's own moves in that verb,
where the guard reads the arguments and tells them apart.

Judged per command segment against the repo that segment targets, the
guard denies four shapes:

1. a `checkout` or `switch` entering that repo's default branch while
   its tracked tree is dirty;
2. a `checkout -b|-B` or `switch -c|-C` whose new branch is named as the
   default branch;
3. an irrecoverable discard through `reset` or `stash`: `git reset`
   carrying `--hard`, `--merge` or `--keep`, and `git stash drop` or
   `git stash clear`, each of them dropping work no `pop` and no reflog
   brings back;
4. a whole-tree path restore: a `checkout` or `restore` one of whose
   pathspecs names a whole tree - `.`, `./`, `:/`, `:/.`, or a path
   resolving to the repo's top level - while a restore naming its
   paths passes, which is how a seat undoes one file and how
   `git restore --staged <paths>` unstages.

The spellings each shape catches, the commands it passes and its reason
line are the guard's own: `hooks/dev-branch-guard.sh` and its test
`scripts/test/dev-head-guard.test.sh`.

## Bash prefix set

One run-wide set of `Bash(<prefix>:*)` rules, the prefix being the
declared command up to its first placeholder with the trailing space
trimmed. No Bash allow rule is derived per seat under either supervisor
mode: an allow rule lives in a settings tier the whole session reads,
and a definition carries `tools:` and no permission key.

A host command's rule is as narrow as the command. A rule's `*`
matches any text, spaces included, so no allow rule bounds the flags
after `<n>`: a REST host command, whose `gh api` rule would reach every
write under its endpoint, is declared as a shipped script taking its
placeholders alone, its rule the script's path (`toolchain.md § State
check`). A `gh pr merge` rule reaches every flag of `gh pr merge`,
`--admin` among them, which merges past a failing required check, so
the pre-flight declares the deny `Bash(gh *--admin*)` beside it, deny
rules being evaluated before allow rules. The deny is checked as the
carve-out's are (§ Mode-independent set): its exact string in a tier's
`deny`, a missing one being a gap `--apply` cannot close. It binds in
every mode, so it is checked under `autoMode.classifyAllShell` too. A
tier deny carrying literal text after its wildcard bars only the
commands carrying that text, so the pre-flight reads it as reaching no
declared allow rule but its own string.

| Rule | Source |
| --- | --- |
| `Bash(git status:*)`, `Bash(git diff:*)`, `Bash(git log:*)`, `Bash(git show:*)`, `Bash(git branch:*)`, `Bash(git rev-parse:*)` | the seat definitions: every seat holds `Bash`, the read-only seat holds `Read, Bash` alone (`agents/dev-cold-reader.md`), and `agents/code-reviewer.md` reads state with `git diff`/`log`/`show` |
| `Bash(sed:*)`, `Bash(grep:*)`, `Bash(head:*)`, `Bash(tail:*)`, `Bash(awk:*)`, `Bash(wc:*)`, `Bash(cat:*)`, `Bash(ls:*)` | the same definitions: no seat holds `Glob` or `Grep`, so these are what the seats read and search with |
| `Bash(echo:*)` | `branch-plan.md § Commit cadence` point 4 |
| `Bash(git add:*)`, `Bash(git commit:*)` | `branch-plan.md § Commit cadence` 3 |
| `Bash(git switch:*)` | `run.md § Pre-flight`'s branch cut off the default, which spells no verb: both spellings that cut a branch are declared, `git checkout -b` and `git switch -c`, and the guard's second shape judges them alike |
| `Bash(git checkout:*)`, `Bash(git pull:*)` | `finish.md § 4` step 1's sync of the default branch, and `finish.md § 3`'s discard entry into it |
| `Bash(git fetch:*)` | `finish.md § 4` step 1's fast-forward of the local default branch from a dirty tree, which stays on the merged branch |
| `Bash(git restore:*)` | § HEAD moves and whole-tree discards: a seat undoing one named file, and the `--staged` unstage route |
| `Bash(git merge:*)` | `run.md § Close` 5 and `finish.md` |
| `Bash(git tag:*)` | `run.md § Pre-flight`'s batch tag |
| `Bash(git read-tree:*)` | `run.md § Question resolution`'s halt revert |
| `Bash(git check-ignore:*)` | `companions/untracked-claude.md § Detection`, which `finish.md § 1`'s bookkeeping line reaches |
| `Bash(git grep:*)` | `companions/verification-policy.md § Verification modality`'s negative-search rule, the instrument the docs verifier is sent to through `companions/documentation.md § Verification gate` (`agents/dev-docs-verifier.md`) |
| one `Bash(git push -u origin <prefix>/*)` per prefix, the strings' one home being `toolchain.md § Permission carve-out` 1 | `finish.md § 3` step 2's `git push -u origin <branch>` at `run.md § Checkpoint`'s accept; declared under carve-out pattern 1 alone |
| `Bash(gh pr view:*)`, `Bash(glab mr view:*)` | `CLAUDE.md § Agent toolchain`'s State-check line |
| `Bash(gh pr checks:*)`, `Bash(glab ci status:*)` | `CLAUDE.md § Agent toolchain`'s CI wait line |
| the project's declared commands | `CLAUDE.md § Agent toolchain` |
| `Bash(gh *--admin*)`, a deny | `CLAUDE.md § Agent toolchain`'s Merge line, where its rule is `Bash(gh pr merge:*)` (`toolchain.md § Merge`) |

An entry one conduct section bars in one context and a definition needs
in another stays, traced to the need, the bar standing where it is
written: `sed`, `awk`, `cat`, `head`, `tail`, `wc` and `grep` are what
the seats read and search with, `sed` editing Markdown under
`rules/writing-artifacts.md § Editing Markdown`, while the config
paragraph of `agents/dev-implementer.md § Steps` keeps every edit off
the settings surface. The
read-only bar in the `§ Steps` of `agents/dev-cold-reader.md`,
`agents/dev-docs-verifier.md` and `agents/code-reviewer.md` keeps every
write of those seats off the checkout, the config directory and the
settings surface.
`echo` stands beside them as the write-capable verb, writing wherever
a redirection points, under those same bars. The push block is that
shape from the runner's side - the push is `run.md § Checkpoint`'s
accept, so `branch-plan.md § Rails`' "Seats never push" stands as
written and no seat definition and no § Seat tool sets row changes for
it.

A rule enters this set only with the step or dispatch companion that
runs it named, and the walk goes both ways: a step whose commands change
is read against the set in the other direction too, each command looked
up rather than the rules alone being read outward. So the next change to
either side walks both ways. The rule promises no completeness - the
commands a run's work products call cannot be enumerated in advance -
and a command no declared rule reaches goes to the owning initiative's
backlog rather than to a named-exclusion list here.

## Workspace trust

`~/.claude.json`'s `projects[<project path>].hasTrustDialogAccepted` is
a host gate on the same footing as the guard above, not a rule: an
untrusted workspace has its project-tier allow entries ignored
wholesale, and the tier the pre-flight's `--apply` writes,
`.claude/settings.local.json`, is project-scoped too, so trust nullifies
exactly what the pre-flight could write. It is the pre-flight's first
check and never its to write: untrusted stops the run with a printed
remedy for the **user**, the settings surface being no seat's
(`run.md § Seats`, the asked-of row).

## Prompt classes

A **pre-flight defect** is a gap in the declared set the run's mode
reads, including a compound command that offers no prefix for a Bash
rule to match. Its
fix is a rule in this file and the tier that carries it. Under
`Supervisor: AI` it halts the item and nobody clears it; under
`Supervisor: human` the user answers the prompt it raises, so a missing
allow rule halts no run and the pre-flight reports it without failing
(`run.md § Seats`, the prompt row).

A **classifier event** under `auto` is no gap in any declared set: the
denial lands inside a dispatched seat's own call and no other seat can
see it, the seat's only channel being its report, whose statuses
(`agents/dev-implementer.md § Outputs`) carry no classifier
class. So the seat handles the call itself, rewriting it to be
classifier-readable where the classifier could not evaluate it and
never retrying a denied call, which the classifier can flag as a
bypass attempt (`companions/supervisor-runbook.md § Failure modes`). What
tells the seat that is its own contract (`agents/dev-implementer.md
§ Steps`), the runbook being no seat's input. A denial is an answer:
the seat reports BLOCKED with the classifier's text, which halts the
item and reports with its work intact (`run.md § Dispatch per item`).
No record of these events is kept anywhere.

A denial of the runner's own command - `git merge`, `git tag`, the
halt's `git read-tree` - lands in the runner's call rather than a
seat's and takes the same route: no retry, the denial halting the run
and reporting, nobody being able to clear a denial for it.

## Seat tool sets

A seat's tool set is its definition's `tools:` key and every seat has
one, the roster being `run.md § Seats`, so the tool set is the per-seat
scope boundary: no seat holds a tool its definition omits. Each set is
cited to its file under `agents/` rather than copied here, a copy
drifting from the definition.

The declared set gates the tools the definitions do name. The Edit-class
rule reaches only the seats whose definitions carry an edit tool, the
cold reader holding `Read, Bash` alone; the
non-Bash allow class covers `WebSearch` and the WebFetch domains for the
two seats holding those tools, and `Skill(<name>)` where a dispatch
names a skill. Every seat holds `Bash` and none holds `Glob` or `Grep` -
a `tools:` name this client's registry does not provide is dropped
silently - so the seats search through `Bash` and the prefix set carries
the search commands.

## Machine-readable form

`companions/auto-permissions.template.json`, a settings object with
`permissions.allow` and `permissions.deny`. Its name and shape are
fixed: `scripts/worker-workspace.sh` reads it by absolute path,
hard-fails if it is absent and consumes those two keys, and
`scripts/test/worker-workspace.test.sh` asserts the filename.

The split is computed, not stored: an allow entry beginning `Bash(`
belongs to the Bash prefix set, every other entry to the mode-independent
allow set.

The template ships no `WebFetch(domain:...)` entry, that class having no
default member, while `WebSearch` ships. Its `deny` keeps
`Bash(git push:*)` alone, the template being what a fresh adopter starts
from and pattern 2 that starting point; pattern 1 is a tier edit
`toolchain.md § Permission carve-out` shows, never a template one, its
deny pair and its checkpoint-push allow block alike. Its
`allow` keeps `Bash(git switch:*)`, `Bash(git checkout:*)` and
`Bash(git restore:*)`: the bar on
a seat's HEAD moves is the guard above, so no deny rule of the declared
set names a HEAD-moving verb, and the allow rules that do are what the
flow's own moves need.

It carries no `Bash(cd:*)` rule: a bare `cd` changes nothing that
outlives its segment, and a `cd` inside a compound command is what no
prefix rule matches. It carries no `Read` rule for a settings tier
either, no source naming a seat that reads one.

## Auto-mode template

`companions/auto-mode.template.json` is the run's `autoMode` block,
read by the `auto` classifier: an environment entry describing a DEV
run and soft_deny entries for the action-level always-ask list of
`companions/declarations.md § Supervisor bounds`, with no allow entry.
Each list keeps `"$defaults"`, which splices Claude Code's built-in
entries in at that place; a list without it replaces them. The template sets no
`classifyAllShell`, so narrow Bash allow rules keep binding under `auto`
(§ What enforces what).

Claude Code reads `autoMode` from the user tier,
`~/.claude/settings.json`, from managed settings and from the
`--settings` flag or the Agent SDK, combining the entries of each. It
never reads `autoMode` from a project's `.claude/settings.json` or
`.claude/settings.local.json`, so neither a project tier nor the
pre-flight's `--apply` can carry the template. The user merges its
entries into their user tier, the settings surface being no seat's
(`run.md § Seats`, the asked-of row); nothing in the toolset reads the
template by path.

The declared merge's allow rule (`toolchain.md § Permission carve-out`)
keeps a merge it matches off the classifier, so the soft_deny
entries naming a merge - a `release/` branch's, an instruction
change's, one past a red gate - never judge it. Those merges stay with
`run.md § Merge or ask` and with the host's required check, which the
`--admin` deny beside a `gh pr merge` rule, a settings-tier rule
(§ Bash prefix set), keeps binding. The template is unchanged by it:
its entries judge every action no allow rule matches.
