#!/usr/bin/env bash
# Tests the host command forms skills/dev/companions/toolchain.md gives, run
# over the host's recorded responses: the REST state check is one read-only
# `gh api` call printing the pull request's state, merge time and head sha.
# Run: bash scripts/test/toolchain-forms.test.sh
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
DOC="$ROOT/skills/dev/companions/toolchain.md"
[ -f "$DOC" ] || { echo "not ok - $DOC not found"; exit 1; }
command -v jq >/dev/null || { echo "not ok - jq not found"; exit 1; }
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }

# The fenced lines of the toolchain.md section headed $1 that start with $2.
form() {
  awk -v h="## $1" -v p="$2" '
    /^## / { on = ($0 == h); next }
    on && /^```/ { fence = !fence; next }
    on && fence && index($0, p) == 1' "$DOC"
}

# The `--jq` filter of the command $1, its single quotes dropped.
jq_filter() { printf '%s\n' "$1" | sed -n "s/.*--jq '\([^']*\)'.*/\1/p"; }

# --- REST state check ------------------------------------------------------
# GET repos/concentrator/claude-dev/pulls/621, trimmed to the fields the
# filter could confuse: a merged pull request, its base sha beside its head's.
PULL='{"number":621,"state":"closed","merged":true,
  "merged_at":"2026-10-30T16:21:02Z",
  "head":{"ref":"mnt/cloud-install","sha":"e84d8d7f7450479c566711bf607c42552175d4db"},
  "base":{"ref":"main","sha":"e672b54233e6163b43014e990911bf3dc595b0dd"}}'
WANT='{"head_sha":"e84d8d7f7450479c566711bf607c42552175d4db","merged_at":"2026-10-30T16:21:02Z","state":"closed"}'

rest=$(form "State check" "gh api ")
if [ "$(printf '%s' "$rest" | grep -c .)" -eq 1 ]; then
  pass "State check gives one gh api form"
else
  die "State check gives one gh api form (found: ${rest:-none})"
fi
case "$rest" in
  "gh api repos/{owner}/{repo}/pulls/<n> "*) pass "the form reads the pull request by number" ;;
  *) die "the form reads the pull request by number (got: ${rest:-none})" ;;
esac
case " $rest " in
  *" -X"* | *" --method"* | *" -f "* | *" -F "* | *" --field"* | *" --raw-field"* | *" --input"* | *graphql*)
    die "the form is a plain GET, no method, field, input or graphql (got: $rest)" ;;
  *) pass "the form is a plain GET, no method, field, input or graphql" ;;
esac
filter=$(jq_filter "$rest")
got=$(printf '%s' "$PULL" | jq -cS "${filter:-empty}" 2>/dev/null)
if [ "$got" = "$WANT" ]; then
  pass "the form prints state, merge time and head sha, no checks"
else
  die "the form prints state, merge time and head sha, no checks (got: ${got:-nothing})"
fi

exit $fail
