#!/usr/bin/env bash
# Tests scripts/rest-state-check.sh, the REST state check, through a stand-in
# `gh`: it takes the pull request number alone, makes one plain `gh api` GET of
# that pull request, exits with gh's status, and refuses any other arguments
# before calling gh. What the call prints is toolchain-forms.test.sh's.
# Run: bash scripts/test/rest-state-check.test.sh
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT="$ROOT/scripts/rest-state-check.sh"
[ -f "$SCRIPT" ] || { echo "not ok - $SCRIPT not found"; exit 1; }
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

# The stand-in: logs each call's arguments to $CALLS, one per line and a blank
# line after the call, prints $OUT and exits $RC.
mkdir -p "$W/bin"
cat > "$W/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" '' >> "$CALLS"
printf '%s\n' "$OUT"
exit "$RC"
EOF
chmod +x "$W/bin/gh"

# One run: the stand-in printing $1 and exiting $2, the script run on the rest.
run() {
  local out=$1 rc=$2; shift 2
  : > "$W/calls"
  got=$(CALLS="$W/calls" OUT="$out" RC="$rc" PATH="$W/bin:$PATH" bash "$SCRIPT" "$@" 2>&1); code=$?
  calls=$(grep -c '^$' "$W/calls")
}

# PR 621's line, as the probe printed it.
LINE='{"head_sha":"e84d8d7f7450479c566711bf607c42552175d4db","merged_at":"2026-10-30T16:21:02Z","state":"closed"}'
run "$LINE" 0 621
[ "$code" -eq 0 ] && [ "$got" = "$LINE" ] && pass "a read prints gh's line and exits 0" \
  || die "a read prints gh's line and exits 0 (got $code: $got)"
[ "$calls" -eq 1 ] && pass "it makes one call" || die "it makes one call ($calls)"
want=$(printf '%s\n' api 'repos/{owner}/{repo}/pulls/621' --jq '{state, merged_at, head_sha: .head.sha}' '')
[ "$(cat "$W/calls")" = "$want" ] && pass "the call is a plain GET of the pull request, filtered to state, merge time and head sha" \
  || die "the call is a plain GET of the pull request, filtered to state, merge time and head sha (got: $(tr '\n' ' ' < "$W/calls"))"

run '{"message":"Not Found","status":"404"}' 1 9999999
[ "$code" -eq 1 ] && pass "a host error exits with gh's status" || die "a host error exits with gh's status (got $code)"

for args in "" "x" "621 --method" "621 622" "-X"; do
  run "" 0 $args
  if [ "$code" -eq 2 ] && [ "$calls" -eq 0 ]; then
    pass "arguments '${args}': usage exit 2, no call"
  else
    die "arguments '${args}': usage exit 2, no call (got $code, $calls calls)"
  fi
done

exit $fail
