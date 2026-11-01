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
  Call: `GH_DEBUG=api scripts/rest-ci-wait.sh 624` and `... 625`, run
   side by side as soon as each pull request's head took a new commit,
   the debug stream on stderr filtered to its request lines and
   searched for `graphql`; before them, the second probe confirming the
   values `scripts/test/rest-ci-wait.test.sh` pins: `gh api
   repos/{owner}/{repo}/pulls/<n>` and `.../commits/<sha>/check-runs`
   on both pull requests' first heads
  Output:
   second probe: pulls/624 head 9c78d2abb40316cfa177699d43e7f816acd423e6,
    pulls/625 head afeeaad37794fd9c885f45e8a9e017e52f08a6d2, both on
    base bbb156f2bfda5f40c07c08daea1c03688ff9f057; check run tier1
    completed success on the first, completed failure on the second,
    the job URLs the test pins; graphql lines: 0 on each of the 4 calls
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
   each wait's 11 polls: total_count 0 once, then tier1 in_progress 9
    times, then completed; the failing job's steps: Tier-1 mechanical
    checks success, Test suites failure
  Environment: gh 2.97.0 on macOS (Darwin 25.5.0), 2026-10-30T17:05Z
   to 17:07Z; concentrator/claude-dev throwaway pull requests 624
   (passing) and 625 (failing late, in the test-suites step), based on
   a throwaway branch cut from main, closed unmerged with their
   branches deleted
  Test: `scripts/test/rest-ci-wait.test.sh` (every case), and
   `scripts/test/toolchain-forms.test.sh` ("CI wait gives the REST
   script on the pull request number")
- Item 3 (probe): The REST merge merges a pull request with a merge commit
  from one REST call carrying the head sha CI verified, making no GraphQL
  request, and exits non-zero when the host refuses the merge, a head moved
  past that sha included.
  Call: `GH_DEBUG=api gh api -X PUT repos/{owner}/{repo}/pulls/627/merge
   -f merge_method=merge -f sha=<sha>`, first with the stale sha
   88b26fc5f28c795d3d8dd9aee0e80398300f6487 (the head's parent), then
   with the head sha 447aadb65dae1acc93e6aac78e03c5e70c23f5da, the debug
   stream on stderr filtered to its request lines and body and searched
   for `graphql`; then `gh api repos/{owner}/{repo}/commits/<merge sha>`
   for the merge commit's parents
  Output:
   stale sha:
   {"message":"Head branch was modified. Review and try the merge again.","documentation_url":"https://docs.github.com/rest/pulls/pulls#merge-a-pull-request","status":"409"}
   exit=1
   > PUT /repos/concentrator/claude-dev/pulls/627/merge HTTP/1.1
   < HTTP/2.0 409 Conflict
   body: {"merge_method":"merge","sha":"88b26fc5f28c795d3d8dd9aee0e80398300f6487"}
   graphql lines: 0
   pulls/627 after it: {"merged":false,"state":"open"}
   head sha:
   {"sha":"175eebd7ff6c1fbdb87db7d1536461e15ac40946","merged":true,"message":"Pull Request successfully merged"}
   exit=0
   > PUT /repos/concentrator/claude-dev/pulls/627/merge HTTP/1.1
   < HTTP/2.0 200 OK
   body: {"merge_method":"merge","sha":"447aadb65dae1acc93e6aac78e03c5e70c23f5da"}
   graphql lines: 0
   merge commit 175eebd7ff6c1fbdb87db7d1536461e15ac40946 parents: the
    base tip c4b6c694894149fe3eceb6c9281260b26532f4c3 and the head sha
    447aadb65dae1acc93e6aac78e03c5e70c23f5da
   first probe, pull request 626: the same 409-then-200 shapes, and a
    second merge call on 626 once merged answered 200 with the same
    merge commit, exit 0
  Environment: gh 2.97.0 on macOS (Darwin 25.5.0), 2026-11-01T16:04Z to
   16:06Z; concentrator/claude-dev throwaway pull requests 626 and 627,
   based on a throwaway base branch cut from main, both merged into that
   base only, the base branch deleted and the head branches deleted by
   the host on merge; main unchanged
  Test: `scripts/test/toolchain-forms.test.sh` ("the merge form PUTs a
   merge commit carrying sha 88b26fc" and "... 447aadb")
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
- Item 2: the answer left the form open; the wait is a script,
  `scripts/rest-ci-wait.sh`, not an inline declared line. A polling
  loop inline is a compound shell command, so the pre-flight's rule for
  it (the line up to its first placeholder) would start at the loop
  keyword and reach far past one GET; the script's rule is its path
  alone. The script takes the pull request number, as the other forms
  do, reads the head sha once and names it on its outcome line.
  `install-dev.sh` ships it in both sets, `LAYOUT.md` lists it, the two
  install tests check it. The declared line spells the installed path
  out (`~/.claude/scripts/rest-ci-wait.sh <n>`), since a `<config>`
  placeholder would end the derived rule before the path. A check
  passes on conclusion `success` alone: `neutral` and `skipped` were
  not observed, and read as failures. The cap is 6 empty polls 10
  seconds apart; `REST_CI_WAIT_INTERVAL` overrides the interval, which
  the test sets to 0. Result: on the probe's live pull requests the
  wait blocked through an unregistered first poll and 9 running polls,
  then exited 0 on the passing one and 1 on the one failing late.
- Item 2: the plan names no test; `scripts/test/rest-ci-wait.test.sh`
  serves the probe's recorded responses through a stand-in `gh` (the
  pass, fail and no-checks cases, the usage exit, GET-only calls), and
  `toolchain-forms.test.sh` gains a check of the CI wait's REST form.
  Result: the first failed before the script existed and passes after
  it; the form check, written after the doc edit, passes.
- Review 1: the entry names the script alone; `toolchain.md § CI wait`,
  which stated the `success`-only pass set, states the widened one too.
  Result: `rest-ci-wait.test.sh`'s new `neutral` and `skipped` cases
  failed before the script change and pass after it.
- Item 3: the plan names no test; `toolchain-forms.test.sh` reads the
  REST merge form from the new `toolchain.md § Merge`, builds the
  request `gh api` sends for it - method, endpoint, the JSON body of its
  `-f` fields - and compares it with the two requests the second probe
  sent on pull request 627. The form puts `-X PUT` before the endpoint,
  so the pre-flight's rule for it, the line up to `<n>`, carries the
  method. § Merge also lists `gh pr merge <n> --merge`, this
  repository's declared merge, as the GraphQL form. The stale case took
  a head two commits deep, sending the first commit's sha, rather than a
  push after the pull request opened: the host sees the same head moved
  past the sha, and the pre-push hook ran once. Result: the test failed
  before the doc edit and passes after it.
- Item 3: the first probe found that a merge call on a pull request
  already merged answers 200 with the same merge commit, exit 0, so
  § Merge counts it no refusal and leaves merged state to the state
  check. Result: § Merge states it beside the 409 refusal.

### Findings
- [x] Item 3: `scripts/test/install-dev-manifest.test.sh` fails on this
  branch, "manifest: 73 records of 72": its count of shipped copies
  adds 25 to the bundled files, and item 2 added
  `scripts/rest-ci-wait.sh` to the install without raising it. The
  fast tier is the lint alone, so only the full suite and the pre-push
  hook show it, the hook printing it on a push from this tree -
  scripts/test/install-dev-manifest.test.sh:26
  Evidence: observed `bash scripts/test/install-dev-manifest.test.sh`
  printing "not ok - manifest: 73 records of 72, bad=0"

## Answers

- Item 2: the REST CI wait polls the head sha's check runs
  (`gh api repos/{owner}/{repo}/commits/<sha>/check-runs`) until every
  run is completed, then exits 0 when each passed and non-zero when one
  failed; the loop is capped, so a run never registered still reaches
  the re-run rule of `git-workflow.md § Merge order`, whose wording on
  polling changes to match. `gh run watch` is not used: it makes one
  GraphQL request, the pull request lookup for its title line. The
  implementer picks an inline declared line or a small helper script,
  whichever keeps item 4's derived rule narrow.
- Item 2: a check passes on conclusion `success`, `neutral` or
  `skipped`; any other conclusion fails the wait.
- Item 4: per the Claude Code permissions page
  (code.claude.com/docs/en/permissions), `Bash(x:*)` matches as
  `Bash(x *)`, a space required after `x`; a `*` anywhere in a rule
  matches any text, spaces included; deny rules are evaluated before
  allow rules, and an allow cannot carve an exception out of a deny. No
  allow glob therefore bounds the flags after `<n>`. The REST state
  check and the REST merge become shipped scripts, as the REST CI wait
  is, each checking its arguments (`<n>`; `<n> <sha>`) and making the
  one REST call its item gives, so each derived rule is the script's
  path alone; the `gh pr merge` rule stays, and the pre-flight derives
  `deny: Bash(gh *--admin*)` beside it.

## Review

- [x] Item 2: `scripts/rest-ci-wait.sh` passes a check on `success`
  alone, so a `neutral` or `skipped` check fails the wait; it passes on
  `success`, `neutral` or `skipped`, each with a test case (Important) -
  scripts/rest-ci-wait.sh
  Evidence: observed the item 2 implementer's report, concern 1
- [x] Item 2: `install-dev-manifest.test.sh` counts the shipped copies
  without `scripts/rest-ci-wait.sh`, so the full suite fails "manifest:
  73 records of 72"; its count takes the new file (Important) -
  scripts/test/install-dev-manifest.test.sh:26
  Evidence: observed `bash scripts/test/install-dev-manifest.test.sh`
  printing "not ok - manifest: 73 records of 72, bad=0"
