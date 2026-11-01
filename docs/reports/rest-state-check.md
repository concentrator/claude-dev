# REST state check

Probe of the GitHub state check for a host CLI with REST only: one
`gh api` GET of a pull request prints its state, merge time and head
sha, making no GraphQL request. The pull request was read only.

## Call

```
GH_DEBUG=api gh api repos/{owner}/{repo}/pulls/621 --jq \
  '{state, merged_at, head_sha: .head.sha}'
```

`GH_DEBUG=api` makes `gh` log each HTTP request it sends to stderr.
That stream was filtered to its request lines and searched for
`graphql`, the count printed as `graphql lines`.

## Output

```
{"head_sha":"e84d8d7f7450479c566711bf607c42552175d4db","merged_at":"2026-10-30T16:21:02Z","state":"closed"}
* Request to https://api.github.com/repos/concentrator/claude-dev/pulls/621
> GET /repos/concentrator/claude-dev/pulls/621 HTTP/1.1
graphql lines: 0
```

The first line is the call's stdout: the pull request's head sha, its
merge time and its state, a merged pull request reading `closed` with
`merged_at` set. The two request lines show the one REST GET the call
sent, and `graphql lines: 0` that no request went to the GraphQL
endpoint.

## Environment

- `gh` 2.97.0 on macOS (Darwin 25.5.0)
- Run at 2026-10-30T16:27Z
- Pull request: `concentrator/claude-dev` 621, merged
