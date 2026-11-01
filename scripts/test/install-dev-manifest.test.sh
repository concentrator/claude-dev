#!/usr/bin/env bash
# Tests what scripts/install-dev.sh owns in its target (scripts/install-manifest.sh):
# the manifest, adoption of its own copies, the user's files left and listed,
# dropped files, and the refusal of its own checkout as target.
# Run: bash scripts/test/install-dev-manifest.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
cd "$(git rev-parse --show-toplevel)"

INSTALL="$PWD/scripts/install-dev.sh"
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
hash() { git hash-object --no-filters "$1"; }
record() { awk -v f="$1" '{ p = $0; sub(/^[^ ]+  /, "", p) } p == f { n++ } END { print n + 0 }' "$C/dev-install-manifest.txt"; }
unrecord() { awk -v f="$1" '{ p = $0; sub(/^[^ ]+  /, "", p) } p != f' "$C/dev-install-manifest.txt" > "$C/m.tmp" && mv "$C/m.tmp" "$C/dev-install-manifest.txt"; }
listed() { grep -qxF "install-dev: left in place, not the install's copy: $C/$1" <<<"$out"; }

P=$(mktemp -d); C="$P/.claude"
bash "$INSTALL" --project "$P" >/dev/null 2>&1 || die "install exits nonzero"

# --- the manifest records every copied file by its blob hash ---
bad=0; n=0
while read -r h f; do n=$((n + 1)); [ "$h" = "$(hash "$C/$f")" ] && [ "$h" = "$(hash "$PWD/$f")" ] || bad=1; done < "$C/dev-install-manifest.txt"
want=$(( $(find skills/dev skills/systematic-debugging skills/dispatching-parallel-agents agents -type f | wc -l) + 28 ))
[ "$bad" = 0 ] && [ "$n" = "$want" ] && pass "manifest records each of the $want copies by its hash" || die "manifest: $n records of $want, bad=$bad"
[ "$(record skills/dev/SKILL.md)" = 1 ] && [ "$(record CLAUDE.md)" = 0 ] && [ "$(record settings.json)" = 0 ] \
  && pass "manifest holds the copies, not the files the install edits" || die "manifest records the wrong set"

# --- a recorded copy left unedited is refreshed ---
printf 'an older copy\n' > "$C/skills/dev/plan.md"
unrecord skills/dev/plan.md; printf '%s  skills/dev/plan.md\n' "$(hash "$C/skills/dev/plan.md")" >> "$C/dev-install-manifest.txt"
# --- an unrecorded file matching a committed version of its path is adopted ---
old=$(git log -2 --format=%H -- skills/dev/SKILL.md | tail -1)
git show "$old:skills/dev/SKILL.md" > "$C/skills/dev/SKILL.md"; unrecord skills/dev/SKILL.md
cmp -s "$C/skills/dev/SKILL.md" skills/dev/SKILL.md && die "fixture: the older SKILL.md matches the current one"
# --- an unrecorded differing file, and an edited recorded one, are the user's ---
printf 'mine\n' > "$C/skills/dev/run.md"; unrecord skills/dev/run.md
printf '# edited\n' >> "$C/hooks/dev-branch-guard.sh"; cp "$C/hooks/dev-branch-guard.sh" "$P/guard.before"
# --- a dropped recorded file goes with its emptied directory; edited, it stays ---
mkdir -p "$C/skills/dev/gone"; printf 'x\n' > "$C/skills/dev/gone/old.md"; printf 'y\n' > "$C/skills/dev/kept.md"
printf '%s  skills/dev/gone/old.md\n%s  skills/dev/kept.md\n' "$(hash "$C/skills/dev/gone/old.md")" "$(printf 'z\n' | git hash-object --stdin)" >> "$C/dev-install-manifest.txt"
# --- a retired hook that is no copy of the install's stays ---
printf 'mine\n' > "$C/hooks/dev-handoff-nudge.sh"

out=$(bash "$INSTALL" --project "$P" 2>&1) || die "re-install exits nonzero: $out"
cmp -s "$C/skills/dev/plan.md" skills/dev/plan.md && [ "$(record skills/dev/plan.md)" = 1 ] \
  && pass "an unedited recorded copy is refreshed" || die "recorded copy not refreshed"
cmp -s "$C/skills/dev/SKILL.md" skills/dev/SKILL.md && [ "$(record skills/dev/SKILL.md)" = 1 ] \
  && pass "an unrecorded committed version is adopted and refreshed" || die "committed version not adopted"
[ "$(cat "$C/skills/dev/run.md")" = mine ] && [ "$(record skills/dev/run.md)" = 0 ] && listed skills/dev/run.md \
  && pass "an unrecorded differing file is left, unrecorded, and listed" || die "user's file: $(head -c 40 "$C/skills/dev/run.md") $out"
cmp -s "$C/hooks/dev-branch-guard.sh" "$P/guard.before" && [ "$(record hooks/dev-branch-guard.sh)" = 0 ] && listed hooks/dev-branch-guard.sh \
  && pass "an edited recorded copy is left, its record dropped, and listed" || die "edited copy overwritten or unlisted"
[ ! -e "$C/skills/dev/gone" ] && [ "$(record skills/dev/gone/old.md)" = 0 ] \
  && pass "a dropped recorded file goes, its emptied directory with it" || die "dropped file or its directory stays"
[ "$(cat "$C/skills/dev/kept.md")" = y ] && listed skills/dev/kept.md && [ "$(record skills/dev/kept.md)" = 0 ] \
  && pass "a dropped file edited since its record stays and is listed" || die "edited dropped file removed or unlisted"
[ "$(cat "$C/hooks/dev-handoff-nudge.sh")" = mine ] && listed hooks/dev-handoff-nudge.sh \
  && pass "a retired hook that is no copy stays and is listed" || die "user's retired-hook file removed or unlisted"
out=$(bash "$INSTALL" --project "$P" 2>&1)
listed skills/dev/run.md && listed hooks/dev-branch-guard.sh && listed hooks/dev-handoff-nudge.sh && ! listed skills/dev/kept.md \
  && pass "a third install still lists the user's files at shipped or retired paths, an unrecorded unshipped one no more" || die "third install lists: $out"
rm -rf "$P"

# --- with no manifest, a committed file the trees dropped goes; any other file under them stays ---
P=$(mktemp -d); C="$P/.claude"
gone=$(git log --diff-filter=D --format= --name-only -- skills/dev | grep -m1 .)
[ -e "$gone" ] && die "fixture: $gone is shipped again"
mkdir -p "$C/${gone%/*}" "$C/agents"; printf 'mine\n' > "$C/agents/mine.md"
git show "$(git log -1 --diff-filter=D --format=%H -- "$gone")^:$gone" > "$C/$gone"
out=$(bash "$INSTALL" --project "$P" 2>&1) || die "first install exits nonzero: $out"
[ ! -e "$C/$gone" ] && ! listed "$gone" && pass "a first install removes a committed version its trees no longer ship" || die "dropped committed file $gone kept: $out"
[ "$(cat "$C/agents/mine.md")" = mine ] && listed agents/mine.md && [ "$(record agents/mine.md)" = 0 ] \
  && pass "a first install leaves and lists any other unshipped file under its trees" || die "user's file under agents/: $out"
rm -rf "$P"

# --- its own checkout is refused as target, symlinked or not ---
H=$(mktemp -d); git init -q "$H/.claude"; mkdir -p "$H/.claude/skills/dev" "$H/l"; touch "$H/.claude/skills/dev/SKILL.md"
ln -s "$H/.claude" "$H/l/.claude"
out=$(cd "$H/.claude" && HOME="$H" bash "$INSTALL" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q 'inside the toolset checkout' <<<"$out" && pass "global install from ~/.claude refused" || die "global self-install (rc=$rc): $out"
out=$(cd "$H/.claude" && bash "$INSTALL" --project "$H/.claude" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q 'inside the toolset checkout' <<<"$out" && pass "--project into the checkout refused" || die "--project self-install (rc=$rc): $out"
out=$(cd "$H/.claude" && HOME="$H/l" bash "$INSTALL" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q 'inside the toolset checkout' <<<"$out" && pass "a target symlinked to the checkout refused" || die "symlinked self-install (rc=$rc): $out"
[ -z "$(cd "$H/.claude" && find . -path ./.git -prune -o -type f -print | grep -v '^./skills/dev/SKILL.md$')" ] \
  && pass "a refused install writes nothing" || die "refused install wrote: $(cd "$H/.claude" && find . -path ./.git -prune -o -type f -print)"
rm -rf "$H"

(( fail == 0 )) && echo "install-dev-manifest.test: OK"
exit $fail
