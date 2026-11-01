#!/usr/bin/env bash
# Tests scripts/rest-merge.sh, the REST merge, through a stand-in `gh` serving
# the host's recorded answers: it takes the pull request number and a full head
# sha, makes one `gh api` PUT sending that sha with a merge commit, exits with
# gh's status - 0 on the merge, non-zero on the host's refusal - and refuses any
# other arguments before calling gh. The request's shape is
# toolchain-forms.test.sh's.
# Run: bash scripts/test/rest-merge.test.sh
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT="$ROOT/scripts/rest-merge.sh"
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

# PUT repos/concentrator/claude-dev/pulls/627/merge in the probe: the head
# sha it merged, and the stale sha the host refused, gh exiting 1 on the 409.
HEAD=447aadb65dae1acc93e6aac78e03c5e70c23f5da
STALE=88b26fc5f28c795d3d8dd9aee0e80398300f6487
MERGED='{"sha":"175eebd7ff6c1fbdb87db7d1536461e15ac40946","merged":true,"message":"Pull Request successfully merged"}'
REFUSED='{"message":"Head branch was modified. Review and try the merge again.","documentation_url":"https://docs.github.com/rest/pulls/pulls#merge-a-pull-request","status":"409"}'

run "$MERGED" 0 627 "$HEAD"
[ "$code" -eq 0 ] && pass "a merge exits 0" || die "a merge exits 0 (got $code: $got)"
case "$got" in *175eebd7ff6c1fbdb87db7d1536461e15ac40946*) pass "a merge prints the merge commit's sha" ;; *) die "a merge prints the merge commit's sha (got: $got)" ;; esac
[ "$calls" -eq 1 ] && pass "it makes one call" || die "it makes one call ($calls)"
want=$(printf '%s\n' api -X PUT 'repos/{owner}/{repo}/pulls/627/merge' -f merge_method=merge -f "sha=$HEAD" '')
[ "$(cat "$W/calls")" = "$want" ] && pass "the call PUTs a merge commit of the sha it was given" \
  || die "the call PUTs a merge commit of the sha it was given (got: $(tr '\n' ' ' < "$W/calls"))"

run "$REFUSED" 1 627 "$STALE"
[ "$code" -ne 0 ] && pass "a refused merge exits non-zero" || die "a refused merge exits non-zero (got 0)"
grep -qx "sha=$STALE" "$W/calls" && pass "the refused call sent the sha it was given" \
  || die "the refused call sent the sha it was given (got: $(tr '\n' ' ' < "$W/calls"))"

for args in "" "627" "x $HEAD" "627 ${HEAD:0:7}" "627 ${HEAD}0" "627 $(printf '%s' "$HEAD" | tr a-f A-F)" \
            "627 --admin" "627 $HEAD --admin" "-X PUT"; do
  run "" 0 $args
  if [ "$code" -eq 2 ] && [ "$calls" -eq 0 ]; then
    pass "arguments '${args}': usage exit 2, no call"
  else
    die "arguments '${args}': usage exit 2, no call (got $code, $calls calls)"
  fi
done

exit $fail
