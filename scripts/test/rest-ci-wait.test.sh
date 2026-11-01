#!/usr/bin/env bash
# Tests scripts/rest-ci-wait.sh, the REST CI wait, over the host's recorded
# responses served by a stand-in `gh`: it blocks until every check run on the
# pull request's head sha completes, exits 0 when each passed - concluded
# `success`, `neutral` or `skipped` - and non-zero when one failed, gives up printing `no checks reported` after a capped number of
# empty polls, and makes only GET requests.
# Run: bash scripts/test/rest-ci-wait.test.sh
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT="$ROOT/scripts/rest-ci-wait.sh"
[ -f "$SCRIPT" ] || { echo "not ok - $SCRIPT not found"; exit 1; }
command -v jq >/dev/null || { echo "not ok - jq not found"; exit 1; }
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

# The stand-in: logs each call's arguments to $CALLS, answers `pulls/<n>` with
# $FIX/pull.json and the nth check-runs call with $FIX/runs.<n>.json, else
# $FIX/runs.json, through the real jq and the call's --jq filter.
mkdir -p "$W/bin"
cat > "$W/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALLS"
[ "$1" = api ] || exit 9
path=$2; shift 2; filter=.
while [ $# -gt 0 ]; do case "$1" in --jq) filter=$2; shift 2 ;; *) shift ;; esac; done
case "$path" in
  */pulls/*) f="$FIX/pull.json" ;;
  */check-runs*) k=$(grep -c check-runs "$CALLS"); f="$FIX/runs.$k.json"; [ -f "$f" ] || f="$FIX/runs.json" ;;
  *) exit 9 ;;
esac
jq -r "$filter" "$f"
EOF
chmod +x "$W/bin/gh"

# GET repos/concentrator/claude-dev/pulls/<n> and commits/<sha>/check-runs, on
# the probe's passing and failing pull requests, trimmed to the fields the
# script could confuse: the base sha beside the head's, a run's status beside
# its conclusion.
BASE=bbb156f2bfda5f40c07c08daea1c03688ff9f057
PASS_SHA=9c78d2abb40316cfa177699d43e7f816acd423e6
FAIL_SHA=afeeaad37794fd9c885f45e8a9e017e52f08a6d2
pull() { printf '{"number":%s,"state":"open","head":{"sha":"%s"},"base":{"sha":"%s"}}\n' "$1" "$2" "$BASE"; }
runs() {  # $1 sha, $2 status, $3 conclusion (JSON), $4 job url
  printf '{"total_count":1,"check_runs":[{"name":"tier1","head_sha":"%s","status":"%s","conclusion":%s,"html_url":"%s"}]}\n' "$1" "$2" "$3" "$4"
}
PASS_URL=https://github.com/concentrator/claude-dev/actions/runs/41093872770/job/124194452174
FAIL_URL=https://github.com/concentrator/claude-dev/actions/runs/41093880335/job/124194478732

# One scenario: fixture dir $1 named by its case, the script run on PR $2.
run() {
  FIX="$W/$1"; CALLS="$FIX/calls"; : > "$CALLS"
  out=$(FIX="$FIX" CALLS="$CALLS" PATH="$W/bin:$PATH" REST_CI_WAIT_INTERVAL=0 bash "$SCRIPT" "$2" 2>&1); rc=$?
  polls=$(grep -c check-runs "$CALLS")
}

mkdir -p "$W/pass" "$W/fail" "$W/empty"
pull 624 "$PASS_SHA" > "$W/pass/pull.json"
runs "$PASS_SHA" in_progress null "$PASS_URL" > "$W/pass/runs.1.json"
runs "$PASS_SHA" completed '"success"' "$PASS_URL" > "$W/pass/runs.json"
pull 625 "$FAIL_SHA" > "$W/fail/pull.json"
runs "$FAIL_SHA" in_progress null "$FAIL_URL" > "$W/fail/runs.1.json"
runs "$FAIL_SHA" completed '"failure"' "$FAIL_URL" > "$W/fail/runs.json"
pull 626 "$BASE" > "$W/empty/pull.json"
printf '{"total_count":0,"check_runs":[]}\n' > "$W/empty/runs.json"

run pass 624
[ "$rc" -eq 0 ] && pass "every check passed: exit 0" || die "every check passed: exit 0 (got $rc: $out)"
[ "$polls" -eq 2 ] && pass "it polls until the running check completes" || die "it polls until the running check completes ($polls polls)"
case "$out" in *"$PASS_SHA"*) pass "its outcome names the head sha it watched" ;; *) die "its outcome names the head sha it watched (got: $out)" ;; esac
grep -qx "api repos/{owner}/{repo}/commits/$PASS_SHA/check-runs.*" "$W/pass/calls" \
  && pass "it reads the check runs of the pull request's head sha" || die "it reads the check runs of the pull request's head sha ($(cat "$W/pass/calls"))"

run fail 625
[ "$rc" -ne 0 ] && pass "a check failed: non-zero exit" || die "a check failed: non-zero exit (got 0: $out)"
[ "$polls" -eq 2 ] && pass "a failing check is waited for until it completes" || die "a failing check is waited for until it completes ($polls polls)"
case "$out" in *tier1*"$FAIL_URL"*) pass "the failed check is named with its job" ;; *) die "the failed check is named with its job (got: $out)" ;; esac

# A check concluding `neutral` or `skipped` passes, as `success` does.
for c in neutral skipped; do
  mkdir -p "$W/$c"
  pull 624 "$PASS_SHA" > "$W/$c/pull.json"
  runs "$PASS_SHA" completed "\"$c\"" "$PASS_URL" > "$W/$c/runs.json"
  run "$c" 624
  [ "$rc" -eq 0 ] && pass "a $c check passes: exit 0" || die "a $c check passes: exit 0 (got $rc: $out)"
  case "$out" in *"tier1	pass	$PASS_URL"*) pass "a $c check is listed as pass" ;; *) die "a $c check is listed as pass (got: $out)" ;; esac
done

run empty 626
[ "$rc" -ne 0 ] && pass "no check registered: non-zero exit" || die "no check registered: non-zero exit (got 0)"
case "$out" in *"no checks reported"*) pass "no check registered prints no checks reported" ;; *) die "no check registered prints no checks reported (got: $out)" ;; esac
[ "$polls" -eq 6 ] && pass "the empty polls are capped at 6" || die "the empty polls are capped at 6 ($polls polls)"

if cat "$W"/*/calls | grep -Eq -- ' (-X|--method|-f|-F|--field|--raw-field|--input)( |$)|graphql'; then
  die "every call is a plain REST GET ($(cat "$W"/*/calls | sort -u))"
else
  pass "every call is a plain REST GET"
fi

FIX="$W/pass" CALLS="$W/usage" PATH="$W/bin:$PATH" bash "$SCRIPT" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "no pull request number: usage exit 2" || die "no pull request number: usage exit 2 (got $rc)"

exit $fail
