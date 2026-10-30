---
task: R089-T004
type: mnt
mode: normal
---

- [x] A project whose `gh pr` answers HTTP 403 "GraphQL is not available"
  declares a REST state check: one `gh api` call printing the pull request's
  state, merge time and head sha, no checks, the CI wait carrying them.
  Approach: probe the form under `GH_DEBUG=api` (no `/graphql` request), then
  `toolchain.md § State check`, `declarations.md § Declared commands`.
- [ ] The REST CI wait blocks until the pull request's checks finish and keeps
  the exit contract: 0 when every check passes, non-zero when one fails, and
  a not-yet-registered case `git-workflow.md § Merge order` re-runs. Approach:
  probe `gh run watch --exit-status` on the head sha's run against check runs
  by head sha, on a passing and a failing pull request, then `toolchain.md
  § CI wait`, and `git-workflow.md § Merge order` only if the signal differs.
- [ ] The REST merge makes a merge commit in one `gh api` call sending the
  head sha `run.md § Boundary verification` 4 matched CI to, so the host
  merges only that commit, and exits non-zero when the host refuses. Approach:
  probe under `GH_DEBUG=api` on a throwaway pull request, with its head sha and
  a stale one, then `toolchain.md` (a § Merge after § CI wait),
  `declarations.md § Declared commands`, the sha's source in `finish.md § 3`.
- [ ] The `/dev run` pre-flight derives each host-command rule as narrow as
  its command: state-check and CI-wait rules, shipped or derived, reach no
  `gh api` write, and a merge rule, the derived `Bash(gh pr merge:*)`
  included, nothing past its merge (no `--admin`). Approach: how a rule
  matches `pulls/<n>` and a flag after `<n>`, then `preflight-permissions.sh`,
  its toolchain test, `seat-permissions.md § Bash prefix set`, auto template.
- [ ] `/dev start` adopts a repository whose `main` already exists: it cuts
  `mnt/dev-scaffold` before § 1's first write, commits the scaffold there and
  delivers it by MR/PR, as `migrate.md § 8` does, protecting `main` as before.
  Approach: the route at the head of `start.md`, then `start.md § 5` and the
  bootstrap bullet of `git-workflow.md § Trunk`.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included. (Batch members: the task
  mark rides the batch branch.)

## Claims

- Item 1 (probe): The REST state check prints a pull request's state, merge
  time and head sha from one REST call, making no GraphQL request.
- Item 2 (probe): The REST CI wait exits 0 when every check passes and
  non-zero when one fails, making no GraphQL request.
- Item 3 (probe): The REST merge merges a pull request with a merge commit
  from one REST call carrying the head sha CI verified, making no GraphQL
  request, and exits non-zero when the host refuses the merge, a head moved
  past that sha included.
- Item 4 (source): Each rule the pre-flight derives from a declared
  state-check, CI-wait or merge line reaches no `gh api` write but the
  declared merge, and no merge rule admits `gh pr merge <n> --admin`.
- Item 5 (source): `/dev start` in a repository whose `main` already exists
  delivers the scaffold through a working branch and an MR/PR.

## Proven

- `gh pr checks <n> --watch` exits 0 when every check passes and non-zero
  when one fails: `docs/reports/gh-pr-checks-watch.md`
- Where the host CLI has REST only, every `gh pr` subcommand fails with HTTP
  403 "GraphQL is not available": `docs/reports/dev-dogfood-report.md`
