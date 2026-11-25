---
task: R088-T010
type: doc
mode: normal
---

- [ ] `git-workflow.md § Releases` states the policy and `release.md` the
  commands: the stamp rides a short-lived `release/vX.Y.Z` branch merged by
  MR/PR, no long-lived release line, fixes rolling forward on `main`, and the
  tag message is the version, `-m "X.Y.Z"`. Approach: § Releases rewritten
  to cite `release.md` step 8, which takes `-m "X.Y.Z"` in place of `<short>`.
- [ ] The release plan's archive move rides the release branch, never a commit
  on the default branch: once step 1 finds every entry `[x]` or the user drops
  the rest, the user is asked and a yes moves it in the stamp commit. Approach:
  `release.md` step 7 takes the move and step 10 goes; `plan.md § Archival`'s
  "offered by the `release` skill" still holds.
- [ ] A release-plan entry's mark rides its task mark: the branch's final
  commit, or for a batch member the batch branch at `batch.md § Batch close` 4,
  never the R's close-out MR/PR. Approach: the backlog cites `branch-plan.md
  § Batches`, but the text is `batch.md § Boundary verification`'s close-out
  bullet, which drops "with the release marking".
- [ ] `/dev plan release` writes the next release plan: the next semver, at
  least one task closed since the last `v*` tag, `<plans>/release-vX.Y.Z.md`
  per `templates.md § Release plan` with the open planned branches the user
  picks, committed on a `plan/` branch. Approach: a `release.md § Release
  plan` section; the SKILL.md `release` row and `templates.md` cite it.
- [ ] `/dev migrate` adds the `comments:` convention line to `CLAUDE.md
  § Conventions` when absent, asked as `start.md § 3` asks it. Approach: the
  Conventions list in `migrate.md § 4`, citing `start.md § 3` for the question
  rather than restating it.
- [ ] Under `release-routine: yes`, `/dev migrate` adds `## [Unreleased]` to the
  CHANGELOG: above the newest entry when one exists, else the `start.md § 3`
  seed. Approach: one sentence in `migrate.md § 4` after the Conventions list.
- [ ] Complete the branch: cleanup (stale/temp data), mark plan complete,
  mark the task `[x]` in the R's `tasks.md` plus any release-plan entry,
  delete the `### R088-T010` backlog lines and heading, commit, the resolved
  task report included. (Batch members: the task mark rides the batch branch.)
