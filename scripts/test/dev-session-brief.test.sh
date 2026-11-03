#!/usr/bin/env bash
# Tests hooks/dev-session-brief.sh - the SessionStart re-brief hook.
# Covers the hook file, the live tree state it injects, the handoff it
# injects once on a fresh context, the plans tree a declaration names,
# and every silent fail-open path.
# Run: bash scripts/test/dev-session-brief.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
unset CLAUDE_PROJECT_DIR
ROOT="$(git rev-parse --show-toplevel)"
HOOK="$ROOT/hooks/dev-session-brief.sh"
EMPTY_HOME=$(mktemp -d); export HOME="$EMPTY_HOME"
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
ctx_of() { printf '%s' "$1" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null; }

# The mechanism exists. Its SessionStart entry is the installer's, pinned by install-dev.test.sh.
[ -x "$HOOK" ] && pass "hook file present and executable" || die "hook file missing"

# A repo with a remote main, a work branch whose plan carries an open item,
# one uncommitted change, and no session file anywhere.
D=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$D" "$EMPTY_HOME"' EXIT   # physical path: git resolves symlinks
git -c init.defaultBranch=main -C "$D" init -q --bare origin
git -c init.defaultBranch=main -C "$D" init -q repo
R="$D/repo"
git -C "$R" config user.email t@e; git -C "$R" config user.name t
mkdir -p "$R/dev/plans/R" "$R/dev/plans/archive"
printf -- '- [x] done\n- [ ] open one\n' > "$R/dev/plans/R/T1.md"
printf -- '- [ ] old open\n' > "$R/dev/plans/R/T0.md"
printf 'clean\n' > "$R/tracked.sh"
git -C "$R" add -A; git -C "$R" commit -qm init
git -C "$R" remote add origin "$D/origin"; git -C "$R" push -q origin main
git -C "$R" checkout -q -b work
printf -- '- [x] done\n- [x] open one\n- [ ] open two\n' > "$R/dev/plans/R/T1.md"
printf -- '- [ ] archived open\n' > "$R/dev/plans/archive/A1.md"
git -C "$R" add -A; git -C "$R" commit -qm "tick one"
printf 'dirty\n' > "$R/tracked.sh"
cd "$R"

out=$(printf '{"session_id":"s1","source":"compact"}' | bash "$HOOK" 2>/dev/null); rc=$?
[ "$rc" -eq 0 ] || die "hook exited $rc on a compact start"
[ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName // empty' 2>/dev/null)" = "SessionStart" ] \
  && pass "output carries the SessionStart envelope" || die "envelope wrong: $out"
ctx=$(ctx_of "$out")
has() { case "$ctx" in *"$2"*) pass "$1" ;; *) die "$1: missing '$2' from: $ctx" ;; esac; }
has "repo injected" "- repo: $R"
has "branch injected" "- branch: work"
has "uncommitted path injected" "M tracked.sh"
has "recent commits injected" "tick one"
has "first open item of the touched plan, with its line" "- plan: dev/plans/R/T1.md line 3: - [ ] open two"
case "$ctx" in *"T0.md"*) die "plan the branch never touched leaked in" ;; *) pass "untouched plan stays out" ;; esac
case "$ctx" in *"archive/"*) die "archived plan leaked in" ;; *) pass "archived plan stays out" ;; esac
[ ! -e "$R/dev/session" ] && pass "no session tree read or written" || die "dev/session created"

ctx=$(ctx_of "$(printf '{"session_id":"s1","source":"resume"}' | bash "$HOOK" 2>/dev/null)")
has "resume start injects the tree too" "- plan: dev/plans/R/T1.md line 3: - [ ] open two"

# A clear or startup start injects the handoff once, with the tree, and
# stays silent without one.
for src in clear startup; do
  o=$(printf '{"source":"%s"}' "$src" | bash "$HOOK" 2>/dev/null)
  [ -z "$o" ] && pass "$src start without a handoff: silent" || die "$src start injected without a handoff: $o"
  printf 'merged: #1\nnext: R001-T002\n' > "$R/.git/dev-handoff.md"
  ctx=$(ctx_of "$(printf '{"source":"%s"}' "$src" | bash "$HOOK" 2>/dev/null)")
  has "$src start injects the handoff" "next: R001-T002"
  has "$src start injects the tree with it" "- branch: work"
  [ ! -e "$R/.git/dev-handoff.md" ] && pass "$src start deletes the handoff" || die "$src start left the handoff"
done
printf 'next: R001-T003\n' > "$R/.git/dev-handoff.md"
ctx=$(ctx_of "$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)")
case "$ctx" in *"R001-T003"*) die "compact start injected the handoff" ;; *) pass "compact start leaves the handoff out" ;; esac
[ -e "$R/.git/dev-handoff.md" ] && pass "compact start keeps the handoff" || die "compact start deleted the handoff"
rm -f "$R/.git/dev-handoff.md"

# The project root the harness names wins over the cwd.
ctx=$(cd / && ctx_of "$(printf '{"source":"compact"}' | CLAUDE_PROJECT_DIR="$R" bash "$HOOK" 2>/dev/null)")
has "CLAUDE_PROJECT_DIR names the repo" "- branch: work"

# A clean tree on a branch with no plan change still injects, with no plan line.
git -C "$R" checkout -q tracked.sh; git -C "$R" checkout -q -b bare main
ctx=$(ctx_of "$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)")
has "clean tree reads clean" "- status: clean"
case "$ctx" in *"- plan:"*) die "plan line without a plan change: $ctx" ;; *) pass "no plan line without a plan change" ;; esac
git -C "$R" checkout -q work

# A declared plans tree whose name carries no `plans/` segment fills the plan
# lines, from the root CLAUDE.md or from .claude/CLAUDE.md.
git -C "$R" checkout -q -b declared main
mkdir -p "$R/var/tracks/R"; printf -- '- [ ] declared open\n' > "$R/var/tracks/R/T1.md"
git -C "$R" add -A; git -C "$R" commit -qm "declared plan"
printf '## Layout\n\n- Plans: var/tracks/\n' > "$R/CLAUDE.md"
ctx=$(ctx_of "$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)")
has "declared plans tree fills the plan line" "- plan: var/tracks/R/T1.md line 1: - [ ] declared open"
rm -f "$R/CLAUDE.md"; mkdir -p "$R/.claude"
printf '## Layout\n\n- Plans: var/tracks\n' > "$R/.claude/CLAUDE.md"
ctx=$(ctx_of "$(printf '{"source":"compact"}' | bash "$HOOK" 2>/dev/null)")
has "plans tree declared in .claude/ fills the plan line" "- plan: var/tracks/R/T1.md line 1: - [ ] declared open"
rm -rf "$R/.claude"; git -C "$R" checkout -q work

# The global-hook dedupe: a project copy stays silent on a start the global
# settings already run the hook for, and injects on one their matcher misses.
H="$D/home"; P="$D/proj/.claude/hooks"; mkdir -p "$H/.claude" "$P"
cp "$HOOK" "$ROOT/hooks/dev-hook-once.sh" "$P/"
jq -n '{hooks:{SessionStart:[{matcher:"compact",hooks:[{type:"command",command:"~/.claude/hooks/dev-session-brief.sh"}]}]}}' > "$H/.claude/settings.json"
out=$(printf '{"session_id":"s1","source":"compact"}' | HOME="$H" bash "$P/dev-session-brief.sh" 2>/dev/null)
[ -z "$out" ] && pass "project copy silent on a start the global settings run it for" || die "project copy injected beside the global hook: $out"
ctx=$(ctx_of "$(printf '{"session_id":"s1","source":"resume"}' | HOME="$H" bash "$P/dev-session-brief.sh" 2>/dev/null)")
has "project copy injects on a start the global matcher misses" "- branch: work"

# Silent paths: each exits 0 with no output.
silent() { # $1 = label, $2 = stdin payload
  local o r; o=$(printf '%s' "$2" | bash "$HOOK" 2>/dev/null); r=$?
  [ "$r" -eq 0 ] && [ -z "$o" ] && pass "$1" || die "$1 (rc=$r, out=$o)"
}
silent "subagent start: silent" '{"session_id":"s1","source":"compact","agent_id":"a1","agent_type":"code-reviewer"}'
silent "malformed input: silent" 'not json{'
N=$(mktemp -d); cd "$N"
silent "outside a git repo: silent" '{"session_id":"s1","source":"compact"}'
cd /; rm -rf "$N"

(( fail == 0 )) && echo "dev-session-brief.test: OK"
exit $fail
