#!/usr/bin/env bash
# Tests the host command forms skills/dev/companions/toolchain.md gives, run
# over the host's recorded responses: the REST state check is one read-only
# `gh api` call printing the pull request's state, merge time and head sha;
# the REST CI wait runs the shipped scripts/rest-ci-wait.sh on the number; the
# REST merge is one `gh api` PUT making a merge commit of the head sha it sends.
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

# --- REST CI wait ----------------------------------------------------------
wait_form=$(form "CI wait" "~/")
if [ "$wait_form" = "~/.claude/scripts/rest-ci-wait.sh <n>" ]; then
  pass "CI wait gives the REST script on the pull request number"
else
  die "CI wait gives the REST script on the pull request number (found: ${wait_form:-none})"
fi
[ -x "$ROOT/scripts/rest-ci-wait.sh" ] \
  && pass "the REST form names a script the repository carries" \
  || die "the REST form names a script the repository carries"

# --- REST merge ------------------------------------------------------------
# The request `gh api` sends for the form: its method, its endpoint before gh
# fills {owner}/{repo}, and its JSON body built from the -f (string) fields.
# A -F field is typed by gh, so a sha of digits alone would leave as a number.
request() {
  local method=GET endpoint="" fields=() t
  set -- $1
  [ "${1:-} ${2:-}" = "gh api" ] || { echo "not a gh api call"; return; }
  shift 2
  while [ $# -gt 0 ]; do
    t=$1; shift
    case "$t" in
      -X | --method) method=$1; shift ;;
      -f | --raw-field) fields+=("$1"); shift ;;
      -*) echo "unexpected option $t"; return ;;
      *) endpoint=$t ;;
    esac
  done
  printf '%s %s ' "$method" "$endpoint"
  jq -cnS '$ARGS.positional | map(capture("^(?<key>[^=]+)=(?<value>.*)$")) | from_entries' \
    --args ${fields[@]+"${fields[@]}"}
}

merge=$(form "Merge" "gh api ")
if [ "$(printf '%s' "$merge" | grep -c .)" -eq 1 ]; then
  pass "Merge gives one gh api form"
else
  die "Merge gives one gh api form (found: ${merge:-none})"
fi
case "$merge" in
  *graphql*) die "the merge form makes no graphql call (got: $merge)" ;;
  *) pass "the merge form makes no graphql call" ;;
esac
# PUT repos/concentrator/claude-dev/pulls/627/merge as `gh api` sent it in
# the probe: the stale sha the host refused, then the head sha it merged.
for sha in 88b26fc5f28c795d3d8dd9aee0e80398300f6487 447aadb65dae1acc93e6aac78e03c5e70c23f5da; do
  want="PUT repos/{owner}/{repo}/pulls/627/merge {\"merge_method\":\"merge\",\"sha\":\"$sha\"}"
  line=${merge//<n>/627}; line=${line//<sha>/$sha}
  got=$(request "$line" 2>&1)
  if [ "$got" = "$want" ]; then
    pass "the merge form PUTs a merge commit carrying sha ${sha:0:7}"
  else
    die "the merge form PUTs a merge commit carrying sha ${sha:0:7} (got: ${got:-nothing})"
  fi
done

exit $fail
