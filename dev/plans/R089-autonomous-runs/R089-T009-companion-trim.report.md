# R089-T009 report

## Implementer

## Answers

- Close review, Review 1: the sentence says the spellings and passes are
  asserted in `dev-head-guard.test.sh` and the reason lines are the
  hook's alone.
- Close review, Review 2: the sentence keeps only the pair split across
  two tiers as untested, and cites case 6b for deny entries beyond the
  pattern's never being a gap.

## Review

- [ ] Item 2: the pointer names the guard and its test as the home of the
  reason lines, but the test asserts allow and deny results only, so the
  reason lines live in the hook alone (Suggestion) -
  skills/dev/companions/seat-permissions.md:140
  Evidence: observed the item 2 implementer's report
- [ ] Item 3: case 6b of `preflight-permissions.test.sh` passes with one
  deny entry beyond the pair, though it tests deny-over-allow narrowing, so
  "names no case for" may read as weaker than the coverage (Suggestion) -
  skills/dev/companions/seat-permissions.md:98
  Evidence: observed the item 3 implementer's report
