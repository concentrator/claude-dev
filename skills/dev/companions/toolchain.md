# Checkpoint push + MR/PR mechanics

Read by `finish`, `run.md`, and `declarations.md`. § State check and
§ CI wait apply everywhere. § Push and the carve-out below are the runner's
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
gh api repos/{owner}/{repo}/pulls/<n> --jq '{state, merged_at, head_sha: .head.sha}'
```

The first two forms return state, merged-at, and checks/pipeline; the
GitHub form's `headRefOid` is the head sha `run.md § Boundary
verification` 4 matches CI to, the rollup's entries carrying no commit
sha. The declared command is a canonical form above - flag shapes like
`--web` are outside it. The view allows ship in
`auto-permissions.template.json`.

A project whose `gh pr` answers HTTP 403 "GraphQL is not available"
declares the REST form: one `gh api` GET, making no GraphQL request,
that prints the pull request's state, merge time and head sha. A merged
pull request reads `closed` with `merged_at` set. The REST form prints
no checks: the CI wait's exit carries them (§ CI wait). `gh` fills
`{owner}/{repo}` from the repository of the current directory.

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
it: `scripts/rest-ci-wait.sh`, which the installer ships. The line
spells the installed path out - `.claude/scripts/rest-ci-wait.sh` for a
project installed with `--project` - since the pre-flight's rule for a
declared command ends at its first placeholder. The script reads the
pull request's head sha once, then polls that sha's check runs through
`gh api` GETs, making no GraphQL request, until every run completes. It
prints one line per check - name, `pass` or `fail`, job URL - and an
outcome line naming the head sha, the one `run.md § Boundary
verification` 4 matches to the state check's `head_sha`. A check passes
when its conclusion is `success`, `neutral` or `skipped`, and fails on
any other. The exit is the canonical forms': 0
when every check passes, non-zero when one fails. A head sha still
without a check run when the script's capped polls run out exits
non-zero printing `no checks reported`, the case `git-workflow.md
§ Merge order` re-runs.

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
             "Bash(glab mr create:*)"],
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
   auto-push - and the `glab mr create` entry beside them is the
   change-request command's rule rather than a push.

2. **Keep the blanket deny** - checkpoint asks, the user approves the
   single `git push -u origin batch/R<NNN>-B<NNN>` manually per batch.
   Zero config; one prompt per batch by design under
   `Supervisor: human`. Under `Supervisor: AI` nobody can answer that
   prompt, so the pre-flight reports it cannot apply.

The pre-flight permission gate checks which pattern is in place and
reports it; it never weakens a deny rule on its own. Which deny strings
the pattern declares, and how the pattern is read off the tiers the
session reads, are `companions/seat-permissions.md § Mode-independent
set`.
