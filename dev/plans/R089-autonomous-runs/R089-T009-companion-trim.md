---
task: R089-T009
type: mnt
mode: normal
---

- [ ] `toolchain.md` § State check, § CI wait and § Merge each state their
  REST form in one line naming its script, whose header gives the call,
  output and exit; the shipped-script paragraph stays, `README.md` citing
  it. Approach: a behavior only the prose states (the merge's `-f` sha, an
  already-merged exit 0) moves into its script's header first; the fenced
  forms `toolchain-forms.test.sh` reads stay unchanged.
- [ ] `seat-permissions.md § HEAD moves and whole-tree discards` keeps one
  sentence on why the guard, not a deny, holds a seat off HEAD, the four
  shapes, and a pointer to `hooks/dev-branch-guard.sh` and its test
  `dev-head-guard.test.sh` for spellings, passes and reason lines. Approach:
  the heading stays (the guard's reason line cites it); the `git restore`
  row of § Bash prefix set still finds its source.
- [ ] `seat-permissions.md § Mode-independent set` leaves how the carve-out
  pattern is read off the tiers to the pre-flight's carve-out check and
  `preflight-permissions.test.sh`, the paragraph and its bullets becoming a
  pointer; each pattern's deny strings, the missing-deny remedy and this
  repository's pair stay. Approach: that section, then the pointers in
  § Bash prefix set and `toolchain.md § Permission carve-out`'s last line.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  commit, the resolved task report included. (Batch members: the task
  mark rides the batch branch.)

## Claims

- none

## Proven

- none
