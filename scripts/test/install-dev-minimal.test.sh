#!/usr/bin/env bash
# Tests scripts/install-dev.sh --minimal - the contributor set. The full set
# and the shared steps are covered by install-dev.test.sh.
# Run: bash scripts/test/install-dev-minimal.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
cd "$(git rev-parse --show-toplevel)"

INSTALL="$PWD/scripts/install-dev.sh"
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }

# --- --minimal: delivery skill files only, no router, bundled skills, seat
# definitions or cited rules; the rest of the set unchanged; over a full
# install it drops the rest of the full set ---
N=$(mktemp -d)
bash "$INSTALL" --project "$N" >/dev/null 2>&1 && bash "$INSTALL" --project "$N" --minimal >/dev/null 2>&1 || die "minimal install exits nonzero"
got=$(cd "$N/.claude/skills/dev" && find . -type f | sed 's|^\./||' | sort | tr '\n' ' ')
want="companions/auto-permissions.template.json companions/declarations.md companions/secrets.md companions/toolchain.md companions/untracked-claude.md finish.md git-workflow.md "
[ "$got" = "$want" ] && pass "minimal ships only the delivery skill files" || die "minimal skills/dev holds: $got"
[ "$(ls "$N/.claude/skills")" = dev ] && [ "$(cd "$N/.claude/skills/dev" && find . -mindepth 1 -type d)" = ./companions ] \
  && pass "minimal over full drops the bundled skills and the emptied directories" || die "minimal over full left: $(ls "$N/.claude/skills" | tr '\n' ' ')"
[ ! -e "$N/.claude/agents" ] && [ "$(ls "$N/.claude/rules")" = writing-artifacts.md ] \
  && pass "minimal over full drops the seat definitions and the cited rules" || die "minimal over full left: $(ls "$N/.claude/agents" "$N/.claude/rules" 2>/dev/null | tr '\n' ' ')"
M2=$(mktemp -d); bash "$INSTALL" --project "$M2" --minimal >/dev/null 2>&1 || die "fresh minimal install exits nonzero"
[ "$(ls "$M2/.claude/skills")" = "dev" ] && pass "minimal ships no bundled skills" || die "minimal skills/ holds: $(ls "$M2/.claude/skills" | tr '\n' ' ')"
[ ! -e "$M2/.claude/agents" ] && [ "$(ls "$M2/.claude/rules")" = writing-artifacts.md ] \
  && pass "minimal ships no seat definitions or cited rules" || die "minimal ships: $(ls "$M2/.claude/agents" "$M2/.claude/rules" 2>/dev/null | tr '\n' ' ')"
miss=
for f in hooks/dev-branch-guard.sh hooks/dev-secrets-guard.sh hooks/dev-branch-state.sh hooks/dev-session-brief.sh \
         scripts/ci/check-plan-text.sh scripts/ci/check-archival.sh scripts/ci/branch-diff.sh scripts/preflight-permissions.sh scripts/rest-ci-wait.sh scripts/rest-state-check.sh scripts/rest-merge.sh writing.md dev-instructions.md rules/writing-artifacts.md MAINTENANCE.md; do
  [ -f "$M2/.claude/$f" ] || miss="$miss $f"
done
[ -z "$miss" ] && pass "minimal keeps hooks, checks, pre-flight, REST host scripts, writing, instructions and maintenance" || die "minimal missing:$miss"
out=$(bash "$M2/.claude/scripts/test/preflight-permissions.test.sh" 2>&1); rc=$?
[ $rc -eq 0 ] && pass "vendored pre-flight self-test passes from a minimal install" \
  || die "vendored pre-flight self-test failed under minimal: $(grep -m2 'not ok' <<<"$out")"
jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(test("dev-branch-guard"))' "$M2/.claude/settings.json" >/dev/null \
  && pass "minimal registers the hooks" || die "minimal registered no branch-guard"
rm -rf "$N" "$M2"

(( fail == 0 )) && echo "install-dev-minimal.test: OK"
exit $fail
