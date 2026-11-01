# REST CI wait exit status

Probe of `scripts/rest-ci-wait.sh`, the GitHub CI wait for a host CLI
with REST only: it exits 0 when every check passes and non-zero when
one fails, making no GraphQL request. It ran on two throwaway pull
requests, one passing and one failing late, as each took a new commit.

## Call

```
GH_DEBUG=api scripts/rest-ci-wait.sh 624
GH_DEBUG=api scripts/rest-ci-wait.sh 625
```

The two calls ran side by side as soon as each pull request's head took
a new commit, so each wait started before its checks registered.
`GH_DEBUG=api` makes `gh` log each HTTP request it sends to stderr; that
stream was filtered to its request lines, counted per endpoint, and
searched for `graphql`. Each call's exit status is printed as `exit=`.

Before them, a read of both pull requests' first heads confirmed the
values the script's test serves:

```
gh api repos/{owner}/{repo}/pulls/<n>
gh api repos/{owner}/{repo}/commits/<sha>/check-runs
```

## Output

The first heads' read:

- `pulls/624` and `pulls/625`: each read at its first head, before
  the new commit its wait ran on
- both on base `bbb156f2bfda5f40c07c08daea1c03688ff9f057`, "Merge pull
  request #621 from concentrator/mnt/cloud-install" on `main`
- check run `tier1`: completed `success` on the first, completed
  `failure` on the second
- `graphql lines: 0` on each of the 4 calls

The waits:

```
624:
tier1  pass  https://github.com/concentrator/claude-dev/actions/runs/41095726735/job/124200849615
278650aa7739da65db562d1f4c93e92edede5408: all 1 checks passed
exit=0
1 x GET /repos/concentrator/claude-dev/pulls/624
11 x GET /repos/concentrator/claude-dev/commits/278650aa7739da65db562d1f4c93e92edede5408/check-runs?per_page=100
graphql lines: 0
625:
tier1  fail  https://github.com/concentrator/claude-dev/actions/runs/41095724197/job/124200841077
444f454ce6b40990f0627bb3de75efdfe3d12494: 1 of 1 checks failed
exit=1
1 x GET /repos/concentrator/claude-dev/pulls/625
11 x GET /repos/concentrator/claude-dev/commits/444f454ce6b40990f0627bb3de75efdfe3d12494/check-runs?per_page=100
graphql lines: 0
```

Each wait prints one row per check run - its name, `pass` or `fail`,
its job URL - then an outcome line naming the head sha it read. The
request counts show one GET of the pull request, for its head sha,
then 11 GETs of that sha's check runs: the first poll found no check
run registered, the next 9 found `tier1` in progress, the last found it
completed. The failing job's steps were "Tier-1 mechanical checks",
which succeeded, and "Test suites", which failed. `exit=0` follows the
passing wait, `exit=1` the failing one, and `graphql lines: 0` shows no
request went to the GraphQL endpoint.

## Environment

- `gh` 2.97.0 on macOS (Darwin 25.5.0)
- Run from 2026-10-30T17:05Z to 17:07Z
- Pull requests: `concentrator/claude-dev` 624 (passing) and 625
  (failing in the test-suites step), based on a throwaway branch cut
  from `main`, closed unmerged with their branches deleted
