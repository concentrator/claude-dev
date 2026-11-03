# Release

Generic release flow. Projects override via
`<project>/.claude/skills/release/SKILL.md`.

## Pre-conditions

- On default branch, working tree clean.
- `[Unreleased]` section exists in `CHANGELOG.md`.

## Procedure

1. **Verify branch merges.** If `<plans>/release-<version>.md` exists, check
   each branch entry against `git log <default-branch>` - confirm the `[x]`
   marks match merged branches (the marks ride each branch's final commit,
   `branch-plan.md § Closing routine`; verify, never set); flag any planned
   branches not yet merged. Halt if planned branches remain unmerged unless user
   confirms drop.
2. **Diff scope.** `git log $(git describe --abbrev=0 --tags --match 'v*')..HEAD
   --oneline` + stat. Report accumulated changes. The `v*` match finds the last
   release tag, so a `pre-R<NNN>-B<NNN>` batch anchor never reads as a release.
3. **Cut a short-lived branch.** `git checkout -b release/vX.Y.Z` - a
   `release`-prefix branch for the CHANGELOG/notes, delivered by MR/PR (no
   long-lived release line).
4. **Finalize CHANGELOG.** Replace `## [Unreleased]` with `## [vX.Y.Z] -
   <YYYY-MM-DD>`. Drop reverted-change entries.
5. **Reopen `[Unreleased]`.** Add an empty `## [Unreleased]` above the block
   step 4 stamps, for the doc writer's next entries and the next release's
   pre-condition. Prune no ROADMAP entry: a closed R's `[x]` is its closure
   record (`plan.md § Approval and closure`).
6. **Release notes.** Generate from the CHANGELOG diff, as the body of the
   release MR/PR step 8 opens.
7. **Commit on release branch.** Message: `Stamp vX.Y.Z release`.
8. **Hand off.** `git push -u origin release/vX.Y.Z` → CI-gated MR/PR → merge
   to `main`, then tag trunk: `git tag -a vX.Y.Z -m "<short>"` + `git push
   origin vX.Y.Z`. No release branch kept (`git-workflow.md § Releases`).
9. **Project-specific publish.** Run the project's publish step per CLAUDE.md
   (npm/cargo/registry). Skip if not applicable.
10. **Plan cleanup.** If `<plans>/release-<version>.md` is all `[x]`, offer to
    move to `<plans>/archive/`.

## Rules

- Never edit `CHANGELOG.md` on the default branch directly - use the short-lived
  release MR/PR.
- Never auto-tag, push, or amend published commits.
- No code review: each change was reviewed once, at its branch or batch
  close (`run.md § Close` 1, `batch.md § Batch close` 1).
