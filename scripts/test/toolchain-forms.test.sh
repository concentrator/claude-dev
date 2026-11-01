#!/usr/bin/env bash
# Tests the host command forms skills/dev/companions/toolchain.md gives, run
# over the host's recorded responses: each REST form runs a shipped script on
# its placeholders - the state check prints the pull request's state, merge
# time and head sha from one read-only `gh api` call, the CI wait runs
# scripts/rest-ci-wait.sh on the number, and the merge is one `gh api` PUT
# making a merge commit of the head sha it sends.
# Run: bash scripts/test/toolchain-forms.test.sh
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
DOC="$ROOT/skills/dev/companions/toolchain.md"
[ -f "$DOC" ] || { echo "not ok - $DOC not found"; exit 1; }
command -v jq >/dev/null || { echo "not ok - jq not found"; exit 1; }
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

# The fenced lines of the toolchain.md section headed $1 that start with $2.
form() {
  awk -v h="## $1" -v p="$2" '
    /^## / { on = ($0 == h); next }
    on && /^```/ { fence = !fence; next }
    on && fence && index($0, p) == 1' "$DOC"
}

# The stand-in `gh`: logs each call's arguments to $CALLS, one per line and a
# blank line after the call, and answers with $RESPONSE through the real jq
# and the call's --jq filter.
mkdir -p "$W/bin"
cat > "$W/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" '' >> "$CALLS"
filter=.
while [ $# -gt 0 ]; do case "$1" in --jq) filter=$2; shift 2 ;; *) shift ;; esac; done
jq -cS "$filter" "$RESPONSE"
EOF
chmod +x "$W/bin/gh"

# Runs the declared form $1 from this checkout's scripts/, `<n>` filled with
# $2 and `<sha>` with $3, the stand-in answering with the JSON $4. Sets OUT,
# NCALLS, and CALL, the calls' arguments one per line.
run_form() {
  local line=${1/#\~\/.claude\//$ROOT/} words=()
  line=${line//<n>/$2}; line=${line//<sha>/${3:-}}
  read -r -a words <<< "$line"
  printf '%s\n' "$4" > "$W/response"; : > "$W/calls"; OUT=""
  [ "${#words[@]}" -eq 0 ] \
    || OUT=$(CALLS="$W/calls" RESPONSE="$W/response" PATH="$W/bin:$PATH" bash "${words[@]}" 2>&1)
  CALL=$(cat "$W/calls"); NCALLS=$(grep -c '^$' "$W/calls")
}

# --- REST state check ------------------------------------------------------
# GET repos/concentrator/claude-dev/pulls/621, trimmed to the fields the
# filter could confuse: a merged pull request, its base sha beside its head's.
PULL='{"number":621,"state":"closed","merged":true,
  "merged_at":"2026-10-30T16:21:02Z",
  "head":{"ref":"mnt/cloud-install","sha":"e84d8d7f7450479c566711bf607c42552175d4db"},
  "base":{"ref":"main","sha":"e672b54233e6163b43014e990911bf3dc595b0dd"}}'
WANT='{"head_sha":"e84d8d7f7450479c566711bf607c42552175d4db","merged_at":"2026-10-30T16:21:02Z","state":"closed"}'

rest=$(form "State check" "~/")
if [ "$rest" = "~/.claude/scripts/rest-state-check.sh <n>" ]; then
  pass "State check gives the REST script on the pull request number"
else
  die "State check gives the REST script on the pull request number (found: ${rest:-none})"
fi
[ -x "$ROOT/scripts/rest-state-check.sh" ] \
  && pass "the REST state check names a script the repository carries" \
  || die "the REST state check names a script the repository carries"
run_form "$rest" 621 "" "$PULL"
[ "$NCALLS" -eq 1 ] && pass "the form makes one call" || die "the form makes one call ($NCALLS)"
case "$CALL" in
  $'api\nrepos/{owner}/{repo}/pulls/621\n'*) pass "the form reads the pull request by number" ;;
  *) die "the form reads the pull request by number (got: ${CALL:-none})" ;;
esac
if printf '%s\n' "$CALL" | grep -Eqx -- '-X|--method|-f|-F|--field|--raw-field|--input|.*graphql.*'; then
  die "the form is a plain GET, no method, field, input or graphql (got: $CALL)"
else
  pass "the form is a plain GET, no method, field, input or graphql"
fi
if [ "$OUT" = "$WANT" ]; then
  pass "the form prints state, merge time and head sha, no checks"
else
  die "the form prints state, merge time and head sha, no checks (got: ${OUT:-nothing})"
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
# The request `gh api` sends for the call whose arguments, one per line, are
# $1: its method, its endpoint before gh fills {owner}/{repo}, and its JSON
# body built from the -f (string) fields. A -F field is typed by gh, so a sha
# of digits alone would leave as a number.
request() {
  local method=GET endpoint="" fields=() t args=()
  while IFS= read -r t; do [ -n "$t" ] && args+=("$t"); done <<< "$1"
  set -- ${args[@]+"${args[@]}"}
  [ "${1:-}" = api ] || { echo "not a gh api call"; return; }
  shift
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

merge=$(form "Merge" "~/")
if [ "$merge" = "~/.claude/scripts/rest-merge.sh <n> <sha>" ]; then
  pass "Merge gives the REST script on the pull request number and head sha"
else
  die "Merge gives the REST script on the pull request number and head sha (found: ${merge:-none})"
fi
[ -x "$ROOT/scripts/rest-merge.sh" ] \
  && pass "the REST merge names a script the repository carries" \
  || die "the REST merge names a script the repository carries"
# PUT repos/concentrator/claude-dev/pulls/627/merge as `gh api` sent it in
# the probe: the stale sha the host refused, then the head sha it merged.
graphql=0
for sha in 88b26fc5f28c795d3d8dd9aee0e80398300f6487 447aadb65dae1acc93e6aac78e03c5e70c23f5da; do
  want="PUT repos/{owner}/{repo}/pulls/627/merge {\"merge_method\":\"merge\",\"sha\":\"$sha\"}"
  run_form "$merge" 627 "$sha" '{}'
  case "$CALL" in *graphql*) graphql=1 ;; esac
  got=$(request "$CALL" 2>&1)
  if [ "$NCALLS" -eq 1 ] && [ "$got" = "$want" ]; then
    pass "the merge form PUTs a merge commit carrying sha ${sha:0:7}"
  else
    die "the merge form PUTs a merge commit carrying sha ${sha:0:7} (got: ${got:-nothing})"
  fi
done
[ "$graphql" -eq 0 ] && pass "the merge form makes no graphql call" \
  || die "the merge form makes no graphql call"

exit $fail
