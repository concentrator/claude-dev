#!/usr/bin/env bash
# Tests scripts/ci/check-caps.sh - the Tier-1 size gate, mode-file tier:
# a skills/dev/*.md mode file holds to 300 lines and 80 characters a line,
# table rows exempt. Each case runs the real check in a throwaway git repo.
# Run: bash scripts/test/check-caps.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../ci" && pwd)/check-caps.sh"
[ -f "$CHECK" ] || { echo "not ok - $CHECK not found"; exit 1; }
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }

check_in()  { ( cd "$1" && bash "$CHECK" >/dev/null 2>&1 ); }
report_in() { ( cd "$1" && bash "$CHECK" 2>&1 ) || true; }
mkrepo() {
  local d; d=$(mktemp -d); git -C "$d" init -q -b main
  mkdir -p "$d/skills/dev"
  printf '# x\n' > "$d/CLAUDE.md"; printf 'x\n' > "$d/DESIGN.md"
  printf '%s' "$d"
}
lines() { local n=$1; local i; for ((i = 1; i <= n; i++)); do echo "line $i"; done; }
w80=$(printf 'w%.0s' $(seq 1 80))

# 1. 351 lines -> caught, the count named
d=$(mkrepo); lines 351 > "$d/skills/dev/x.md"; git -C "$d" add -A
report_in "$d" | grep -q 'skills/dev/x.md 351 lines > 350' && pass "351 lines caught with the count" || die "351 lines not caught: $(report_in "$d")"
rm -rf "$d"

# 1b. a doc under the declared docs path over 300 lines -> caught; 300 passes
d=$(mkrepo); mkdir -p "$d/docs/sub"; lines 301 > "$d/docs/sub/x.md"; lines 300 > "$d/docs/y.md"; git -C "$d" add -A
out=$(report_in "$d"); [[ $out == *'docs/sub/x.md 301 lines > 300'* && $out != *'docs/y.md'* ]] && pass "doc over 300 lines caught, 300 passes" || die "doc cap: $out"
rm -rf "$d"

# 2. an 81-character prose line -> caught, the line number named
d=$(mkrepo); { echo "short"; echo "${w80}x"; } > "$d/skills/dev/x.md"; git -C "$d" add -A
report_in "$d" | grep -q 'skills/dev/x.md line 2: 81 characters > 80' && pass "81-character line caught with its number" || die "81-character line not caught: $(report_in "$d")"
rm -rf "$d"

# 3. an 81-character table row -> exempt, pass
d=$(mkrepo); { echo "short"; echo "| ${w80}"; } > "$d/skills/dev/x.md"; git -C "$d" add -A
check_in "$d" && pass "table row exempt from the length ceiling" || die "table row wrongly caught: $(report_in "$d")"
rm -rf "$d"

# 4. 350 lines of 80 characters -> pass
d=$(mkrepo); for ((i = 1; i <= 350; i++)); do echo "$w80"; done > "$d/skills/dev/x.md"; git -C "$d" add -A
check_in "$d" && pass "compliant mode file passes" || die "compliant file caught: $(report_in "$d")"
rm -rf "$d"

# 5. 80 characters that are more than 80 bytes -> pass (characters, not bytes)
d=$(mkrepo); printf '%s\n' "$(printf '→%.0s' $(seq 1 80))" > "$d/skills/dev/x.md"; git -C "$d" add -A
check_in "$d" && pass "multibyte line measured in characters" || die "multibyte line wrongly caught: $(report_in "$d")"
rm -rf "$d"

# 6. SKILL.md and companions are outside the tier
d=$(mkrepo); mkdir -p "$d/skills/dev/companions"
lines 351 > "$d/skills/dev/companions/c.md"; git -C "$d" add -A
check_in "$d" && pass "companion outside the tier" || die "companion wrongly caught: $(report_in "$d")"
rm -rf "$d"

commit_in() {
  git -C "$1" add -A
  git -C "$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm "$2"
}
based() { commit_in "$1" base; git -C "$1" checkout -q -b feat; }
words() { local i; for ((i = 1; i <= $1; i++)); do printf 'w '; done; echo; }
skill() {
  mkdir -p "$1/skills/s"
  { echo '---'; echo 'name: s'; echo "description: $(words "$2")"; echo '---'; words "$3"; } \
    > "$1/skills/s/SKILL.md"
}
fails_with() {
  local out; out=$(report_in "$1")
  [[ "$out" == *"$3"* ]] && ! check_in "$1" && pass "$2" || die "$2: [$out]"
}

d=$(mkrepo); lines 120 > "$d/CLAUDE.md"; words 1100 > "$d/DESIGN.md"; skill "$d" 13 310
{ echo short; echo "${w80}x"; lines 358; } > "$d/skills/dev/x.md"; based "$d"
echo more >> "$d/CLAUDE.md"; words 5 >> "$d/DESIGN.md"; words 5 >> "$d/skills/s/SKILL.md"
echo more >> "$d/skills/dev/x.md"; commit_in "$d" grow
check_in "$d" && pass "units over their cap at the base may grow" || die "grown over-cap units caught: $(report_in "$d")"
rm -rf "$d"

d=$(mkrepo); lines 100 > "$d/CLAUDE.md"; lines 100 > "$d/dev-instructions.md"; words 1000 > "$d/DESIGN.md"; based "$d"
echo more >> "$d/CLAUDE.md"; echo more >> "$d/dev-instructions.md"; echo more >> "$d/DESIGN.md"; commit_in "$d" grow
fails_with "$d" "CLAUDE.md taken past its cap" "CLAUDE.md 101 lines > 100"
fails_with "$d" "dev-instructions.md taken past its cap" "dev-instructions.md 101 lines > 100"
fails_with "$d" "DESIGN.md taken past its cap" "DESIGN.md 1001 words > 1000"
rm -rf "$d"

d=$(mkrepo); skill "$d" 12 300; based "$d"; skill "$d" 13 301; commit_in "$d" grow
fails_with "$d" "a description taken past its cap" "skills/s/SKILL.md description 13 words > 12"
fails_with "$d" "a SKILL body taken past its cap" "skills/s/SKILL.md body 301 words > 300"
rm -rf "$d"

d=$(mkrepo); based "$d"; skill "$d" 13 1; commit_in "$d" add
fails_with "$d" "a SKILL added over its cap" "skills/s/SKILL.md description 13 words > 12"
rm -rf "$d"

d=$(mkrepo); lines 340 > "$d/skills/dev/x.md"; based "$d"; lines 20 >> "$d/skills/dev/x.md"; commit_in "$d" grow
fails_with "$d" "a mode file taken past its cap" "skills/dev/x.md 360 lines > 350"
rm -rf "$d"

d=$(mkrepo); { echo short; echo "${w80}x"; echo short; } > "$d/skills/dev/x.md"; based "$d"
printf '\t%sx\n' "$w80" >> "$d/skills/dev/x.md"; commit_in "$d" grow
fails_with "$d" "an added long line fails with its leading tab counted" "skills/dev/x.md line 4: 82 characters > 80"
[[ "$(report_in "$d")" != *"line 2:"* ]] && pass "an old long line stays unreported" || die "old long line reported: $(report_in "$d")"
rm -rf "$d"

d=$(mkrepo); { echo short; echo "${w80}x"; echo short; } > "$d/skills/dev/x.md"; based "$d"
git -C "$d" mv skills/dev/x.md skills/dev/y.md; echo more >> "$d/skills/dev/y.md"; commit_in "$d" move
check_in "$d" && pass "a renamed mode file keeps its old long line" || die "renamed long line caught: $(report_in "$d")"
rm -rf "$d"

d=$(mkrepo); based "$d"; lines 351 > "$d/skills/dev/new.md"
fails_with "$d" "an untracked mode file added over its cap" "skills/dev/new.md 351 lines > 350"
rm -rf "$d"

d=$(mkrepo); lines 120 > "$d/CLAUDE.md"; { echo "${w80}x"; lines 360; } > "$d/skills/dev/x.md"
commit_in "$d" base
check_in "$d" && pass "on main with a clean tree over-cap files pass" || die "clean main caught: $(report_in "$d")"
rm -rf "$d"

[ "$fail" -eq 0 ] && echo "check-caps.test: OK"
exit "$fail"
