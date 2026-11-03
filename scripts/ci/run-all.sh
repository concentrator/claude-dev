#!/usr/bin/env bash
# Tier-1 mechanical gate: run every check, aggregate, fail if any fails.
# Used by .github/workflows/ci.yml and the .githooks/pre-push hook.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

fail=0
failed=""
skipped=""
for c in caps code-size no-em-dash secrets stray plan-integrity archival accretion plan-text todos references batch-tags settings; do
  echo "== check-$c =="
  out="$(bash "scripts/ci/check-$c.sh")" || { fail=1; failed="$failed $c"; }
  printf '%s\n' "$out"
  case "$out" in *"check-$c: SKIP"*) skipped="$skipped $c" ;; esac
done

# The verdict is always the LAST line, both ways - a truncated or
# tail-ed reading can never mistake a failing run for a green one, and
# a skipped check is named rather than folded into a blanket OK.
if (( fail == 0 )); then
  echo "run-all: ALL OK${skipped:+ (skipped:$skipped)}"
else
  echo "run-all: FAILED -$failed"
fi
exit $fail
