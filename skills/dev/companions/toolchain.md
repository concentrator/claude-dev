# Checkpoint push + MR/PR mechanics

Read by `finish`, `run.md`, and `declarations.md`. § State check,
§ CI wait and § Merge apply everywhere. § Push and the carve-out below are the runner's
checkpoint-**accept** mechanics (`run.md § Checkpoint`) - the runner
pushes at no other point and never pushes the default branch. `finish`
pushes its own branch (`finish.md § 3`). The `CLAUDE.md` keys these mechanics
consume - declared commands (`§ Agent toolchain`), supervisor bounds
(`§ Supervision`) - are defined in `declarations.md`.

## State check

MR/PR state (open / merged, checks / pipeline) is read via the declared
state-check command only - one structured call, never text-parsed host
output (`view | grep` pipelines). Canonical forms:

```
gh pr view <n> --json state,mergedAt,statusCheckRollup,headRefOid
# GitLab: glab mr view <iid> --output json
# GitHub, REST only:
~/.claude/scripts/rest-state-check.sh <n>
```

The first two forms return state, merged-at, and checks/pipeline; the
GitHub form's `headRefOid` is the head sha `run.md § Boundary
verification` 4 matches CI to, the rollup's entries carrying no commit
sha. The declared command is a canonical form above - flag shapes like
`--web` are outside it. The view allows ship in
`auto-permissions.template.json`.

A project whose `gh pr` answers HTTP 403 "GraphQL is not available"
declares the REST form, `scripts/rest-state-check.sh`, whose header
gives its call, output and exit.

Each REST form of this file is a script the installer ships, taking its
placeholders and nothing else, rather than a `gh api` line, so its
pre-flight rule is the script's path alone (`seat-permissions.md § Bash
prefix set`). The line spells the installed path out,
`.claude/scripts/<script>` for a project installed with `--project`,
since a `<config>` placeholder would end the rule before the path.

## CI wait

The declared CI wait command blocks until the MR/PR's checks or
pipeline finish. Canonical forms:

```
gh pr checks <n> --watch
# GitLab: glab ci status --branch <branch> --wait
# GitHub, REST only:
~/.claude/scripts/rest-ci-wait.sh <n>
```

`glab ci status` reads a branch's pipeline rather than an MR's, so the
GitLab form names the MR's source branch. The wait allows ship in
`auto-permissions.template.json` beside the view allows.

A project declaring the REST state check declares the REST wait beside
it, `scripts/rest-ci-wait.sh`, whose header gives its calls, output and
exit.

## Merge

The declared merge command merges the MR/PR the CI wait passed, with a
merge commit. Canonical forms:

```
gh pr merge <n> --merge
# GitHub, REST only:
~/.claude/scripts/rest-merge.sh <n> <sha>
```

The pre-flight declares the deny `Bash(gh *--admin*)` beside the
`gh pr merge` rule (`seat-permissions.md § Bash prefix set`); the REST
merge carries none.

A project declaring the REST state check declares the REST merge beside
it, `scripts/rest-merge.sh`, whose header gives its call, output and
exit.

## Push + MR/PR

```
git push -u origin batch/R<NNN>-B<NNN>
gh pr create --head batch/R<NNN>-B<NNN> --base <default> \
  --title "R<NNN>-B<NNN>: <batch theme>" --body-file <report excerpt>
# GitLab: glab mr create --source-branch batch/R<NNN>-B<NNN> --target-branch <default> ...
```

MR/PR description: the report's header block, `## Batch review`, and
`## Judgment calls` sections - not the full per-branch detail (the
report file stays in the repo).

No VCS-host CLI in the project toolchain → push the branch, print the
creation URL/instructions for the user. Never silently skip the
push; deferring is an explicit user choice at the checkpoint. The
pre-flight reads the project's declared commands into the Bash prefix
set (`companions/seat-permissions.md § Bash prefix set`), so an absent
host CLI is this fallback rather than a permission gap.

## Permission carve-out for the checkpoint push

Adopter projects deny `Bash(git push:*)` to keep agents from pushing.
**Deny beats allow across all tiers** - an allow rule cannot override
it. Two working patterns:

1. **Narrow the deny** (recommended for recurring batch projects) - in
   the tracked project `.claude/settings.json`, so a fresh clone keeps
   it (`.claude/settings.local.json` only where the carve-out is
   deliberately machine-local):

   ```json
   "allow": ["Bash(git push -u origin batch/*)",
             "Bash(git push -u origin doc/*)",
             "Bash(git push -u origin feat/*)",
             "Bash(git push -u origin fix/*)",
             "Bash(git push -u origin refactor/*)",
             "Bash(git push -u origin mnt/*)",
             "Bash(git push -u origin test/*)",
             "Bash(git push -u origin plan/*)",
             "Bash(gh pr create:*)"],
   "deny":  ["Bash(git push origin <default>:*)", "Bash(git push --force:*)"]
   ```

   The deny shrinks from all-push to default-branch/force push; the
   allow covers the push of any task branch, not only a batch. Cover
   the prefixes the project actually uses (`git-workflow.md § Trunk`) -
   `batch/*` alone leaves every task-scoped run's push uncovered: a
   prompt outside `auto` and a classifier call under it, auto keeping
   these narrow rules (`companions/seat-permissions.md § What enforces
   what`). The push strings above are a run's own prefixes - one per
   prefix of `git-workflow.md § Trunk` except `release`, whose branch
   `release.md` step 8 pushes by hand under that file's bar on
   auto-push - and the `gh pr create` entry beside them is the
   change-request command's rule rather than a push.

2. **Keep the blanket deny** - checkpoint asks, the user approves the
   single `git push -u origin batch/R<NNN>-B<NNN>` manually per batch.
   Zero push config - the merge's rules below still apply; one prompt
   per batch by design under `Supervisor: human`. Under
   `Supervisor: AI` nobody can answer that prompt, so the pre-flight
   reports it cannot apply.

**The merge, under either pattern.** The declared merge command's rule
comes from the `Merge:` line, up to its first placeholder as the
pre-flight derives it: `Bash(gh pr merge:*)` for the `gh` form, the
script's path for the REST merge. A `Supervisor: AI` runner's merge
needs it in a tier the session reads: under `auto` the classifier
refuses a merge no allow rule matches as "Merge Without Review", even
after an independent review and green CI. A `gh pr merge` project adds
§ Merge's `--admin` deny by hand under either pattern, `--apply` writing
no deny.

The pre-flight permission gate checks which pattern is in place and
reports it; it never weakens a deny rule on its own. Which deny strings
the pattern declares, and how the pattern is read off the tiers the
session reads, are `companions/seat-permissions.md § Mode-independent
set`.
