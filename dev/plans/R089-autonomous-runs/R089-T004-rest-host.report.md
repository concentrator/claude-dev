# R089-T004 report

## Claims
- Item 1 (probe): The REST state check prints a pull request's state, merge
  time and head sha from one REST call, making no GraphQL request.
  Call: `GH_DEBUG=api gh api repos/{owner}/{repo}/pulls/621 --jq
   '{state, merged_at, head_sha: .head.sha}'`, the debug stream on
   stderr filtered to its request lines and searched for `graphql`
  Output:
   {"head_sha":"e84d8d7f7450479c566711bf607c42552175d4db","merged_at":"2026-10-30T16:21:02Z","state":"closed"}
   * Request to https://api.github.com/repos/concentrator/claude-dev/pulls/621
   > GET /repos/concentrator/claude-dev/pulls/621 HTTP/1.1
   graphql lines: 0
  Environment: gh 2.97.0 on macOS (Darwin 25.5.0), 2026-10-30T16:27Z;
   concentrator/claude-dev PR 621 (merged), read only
  Test: `scripts/test/toolchain-forms.test.sh` ("the form prints state,
   merge time and head sha, no checks")
- Item 2 (probe): The REST CI wait exits 0 when every check passes and
  non-zero when one fails, making no GraphQL request.
  Call:
  Output:
  Environment:
- Item 3 (probe): The REST merge merges a pull request with a merge commit
  from one REST call carrying the head sha CI verified, making no GraphQL
  request, and exits non-zero when the host refuses the merge, a head moved
  past that sha included.
  Call:
  Output:
  Environment:
- Item 4 (source): Each rule the pre-flight derives from a declared
  state-check, CI-wait or merge line reaches no `gh api` write but the
  declared merge, and no merge rule admits `gh pr merge <n> --admin`.
  Source:
- Item 5 (source): `/dev start` in a repository whose `main` already exists
  delivers the scaffold through a working branch and an MR/PR.
  Source:

## Implementer
### Divergences
- Item 1: the item names no test, and its probe claim needs one between
  the two probes, so `scripts/test/toolchain-forms.test.sh` reads the
  REST form from `toolchain.md § State check` and runs its `--jq` filter
  over PR 621's recorded response, trimmed to the fields a wrong filter
  could pick (the base sha beside the head's). Items 2 and 3 can extend
  it with their forms. Result: the test pins the line the second probe
  printed, failed before the doc edit and passes after it.

## Review
