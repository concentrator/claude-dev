# REST merge

Probe of the GitHub merge for a host CLI with REST only: one `gh api`
PUT merges a pull request with a merge commit while its head is the sha
sent, making no GraphQL request, and exits non-zero when the host
refuses, a head moved past that sha included. It ran on a throwaway
pull request whose head was two commits past its base.

## Call

```
GH_DEBUG=api gh api -X PUT repos/{owner}/{repo}/pulls/627/merge \
  -f merge_method=merge -f sha=88b26fc5f28c795d3d8dd9aee0e80398300f6487
GH_DEBUG=api gh api -X PUT repos/{owner}/{repo}/pulls/627/merge \
  -f merge_method=merge -f sha=447aadb65dae1acc93e6aac78e03c5e70c23f5da
gh api repos/{owner}/{repo}/commits/175eebd7ff6c1fbdb87db7d1536461e15ac40946
```

The first call sends a stale sha, the head's parent; the second sends
the head sha. `GH_DEBUG=api` makes `gh` log each HTTP request it sends
to stderr; that stream was filtered to its request lines and body and
searched for `graphql`. Each call's exit status is printed as `exit=`.
The third call reads the merge commit's parents.

## Output

The stale sha:

```
{"message":"Head branch was modified. Review and try the merge again.","documentation_url":"https://docs.github.com/rest/pulls/pulls#merge-a-pull-request","status":"409"}
exit=1
> PUT /repos/concentrator/claude-dev/pulls/627/merge HTTP/1.1
< HTTP/2.0 409 Conflict
body: {"merge_method":"merge","sha":"88b26fc5f28c795d3d8dd9aee0e80398300f6487"}
graphql lines: 0
pulls/627 after it: {"merged":false,"state":"open"}
```

The head sha:

```
{"sha":"175eebd7ff6c1fbdb87db7d1536461e15ac40946","merged":true,"message":"Pull Request successfully merged"}
exit=0
> PUT /repos/concentrator/claude-dev/pulls/627/merge HTTP/1.1
< HTTP/2.0 200 OK
body: {"merge_method":"merge","sha":"447aadb65dae1acc93e6aac78e03c5e70c23f5da"}
graphql lines: 0
```

The stale sha drew HTTP 409 "Head branch was modified", `gh` exited 1,
and the pull request stayed open and unmerged. The head sha drew HTTP
200 and the merge commit's sha, `gh` exiting 0. Each request line shows
the one REST PUT the call sent, its body the merge method and sha the
`-f` fields carry, and `graphql lines: 0` that no request went to the
GraphQL endpoint.

The merge commit `175eebd7ff6c1fbdb87db7d1536461e15ac40946` has two
parents: the base tip `c4b6c694894149fe3eceb6c9281260b26532f4c3` and
the head sha `447aadb65dae1acc93e6aac78e03c5e70c23f5da`, so the host
made a merge commit of exactly the sha sent.

An earlier run of the same calls on pull request 626 gave the same
409-then-200 shapes, and a further merge call on 626 once merged
answered 200 with the same merge commit, exit 0.

## Environment

- `gh` 2.97.0 on macOS (Darwin 25.5.0)
- Run from 2026-11-01T16:04Z to 16:06Z
- Pull requests: `concentrator/claude-dev` 626 and 627, based on a
  throwaway base branch cut from `main` and merged into that base only;
  the base branch deleted, the head branches deleted by the host on
  merge, `main` unchanged
