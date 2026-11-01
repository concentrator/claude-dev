#!/usr/bin/env bash
# Tests how scripts/preflight-permissions.sh reads CLAUDE.md § Agent toolchain:
# the section is read from the root CLAUDE.md and .claude/CLAUDE.md, ends with
# its file, and each declared command - the CI wait among them - becomes a Bash
# prefix rule resolved against the tiers.
# Run: bash scripts/test/preflight-permissions-toolchain.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SCRIPT="$ROOT/scripts/preflight-permissions.sh"
TPL="$ROOT/skills/dev/companions/auto-permissions.template.json"
[ -f "$SCRIPT" ] || { echo "not ok - $SCRIPT not found"; exit 1; }
[ -f "$TPL" ] || { echo "not ok - $TPL not found"; exit 1; }
PAIR='["Bash(git push origin main:*)","Bash(git push --force:*)"]'
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
# Physical path: the script canonicalizes --project, and $TMPDIR is a symlink
# on macOS, so an unresolved fixture path would miss every trust lookup.
W=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$W"' EXIT
n=0

# A fresh fixture: a git-initialised project with a toolchain section, a
# trusted workspace and an empty user tier. Sets FIX, PROJ, PT.
newfix() {
  n=$((n + 1)); FIX="$W/$n"; PROJ="$FIX/proj"; PT="$PROJ/.claude/settings.json"
  mkdir -p "$PROJ/.claude"
  git -c init.defaultBranch=main -C "$PROJ" init -q
  git -C "$PROJ" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  printf '## Agent toolchain\n\n- Test (fast): `bash t.sh`\n' > "$PROJ/CLAUDE.md"
  printf -- '\n## Next\n\n- not read: `never run me`\n' >> "$PROJ/CLAUDE.md"
  printf '{"projects":{"%s":{"hasTrustDialogAccepted":true}}}\n' "$PROJ" > "$FIX/claude.json"
  printf '{}\n' > "$FIX/user.json"
}

# A tier satisfying the template's rules, the fixture's toolchain prefix and
# pattern 1's checkpoint-push block, with $2 as the deny set.
sat() {
  jq --arg p "${PROJ#/}" --arg h "${FIX#/}" --argjson d "$2" \
    '{permissions: {allow: ([.permissions.allow[]
       | gsub("__PROJECT_DIR__"; $p) | gsub("__HOME__"; $h)]
       + ["Bash(bash t.sh:*)"]
       + (["batch", "doc", "feat", "fix", "refactor", "mnt", "test", "plan"]
          | map("Bash(git push -u origin " + . + "/*)"))), deny: $d}}' "$TPL" > "$1"
}

runp() {
  OUT=$(HOME="$FIX" PREFLIGHT_USER_SETTINGS="$FIX/user.json" \
        PREFLIGHT_CLAUDE_JSON="$FIX/claude.json" \
        bash "$SCRIPT" --project "$PROJ" "$@" 2>&1); RC=$?
}
# Report lines are column-padded; assertions read them space-collapsed.
has()  { printf '%s\n' "$OUT" | tr -s ' ' | grep -qF -- "$1"; }
want() { has "$1" && pass "$2" || die "$2 - no '$1' in: $OUT"; }
nowant() { has "$1" && die "$2 - unexpected '$1'" || pass "$2"; }
rc0()  { [ "$RC" -eq 0 ] && pass "$1" || die "$1 - rc $RC: $OUT"; }

newfix; mv "$PROJ/CLAUDE.md" "$PROJ/.claude/CLAUDE.md"; printf '# x\n' > "$PROJ/CLAUDE.md"
sat "$PT" "$PAIR"
runp --supervisor human --runner-mode default
rc0 "a toolchain declared in .claude/ exits zero"
want "present (project) Bash(bash t.sh:*)" "a toolchain prefix declared in .claude/ is read"
nowant "never run me" "a span outside the .claude/ toolchain section is not read"

newfix; printf '## Agent toolchain\n\n- Test: `make a`\n' > "$PROJ/CLAUDE.md"
printf -- '- Build: `make b`\n' > "$PROJ/.claude/CLAUDE.md"
sat "$PT" "$PAIR"
runp --supervisor human --runner-mode default
want "Bash(make a:*)" "the first file's toolchain section is read"
nowant "Bash(make b:*)" "the section ends with its file, not in the next one"

newfix; printf '## Agent toolchain\n\n- Test: `make a`\n' > "$PROJ/CLAUDE.md"
printf '## Agent toolchain\n\n- Merge: `gh pr merge <n> --merge`\n' > "$PROJ/.claude/CLAUDE.md"
runp --supervisor human --runner-mode default
want "Bash(make a:*)" "the root file's toolchain section is read"
want "Bash(gh pr merge:*)" "the .claude/ file's toolchain section is read too"

newfix; printf '## Agent toolchain\n\n- CI wait: `glab ci status --branch <branch> --wait`\n' > "$PROJ/CLAUDE.md"
sat "$PT" "$PAIR"
runp --supervisor human --runner-mode default
rc0 "a GitLab CI wait exits zero on the template's rules"
want "present (project) Bash(glab ci status --branch:*)" "the CI wait line is read with the other declared commands"

newfix; sat "$PT" "$PAIR"
edit_rm() { jq --arg r "$1" 'del(.permissions.allow[] | select(. == $r))' "$PT" > "$PT.new" && mv "$PT.new" "$PT"; }
runp --supervisor AI --runner-mode auto
rc0 "a declared toolchain command passes under auto"
want "present (project) Bash(bash t.sh:*)" "auto keeps a narrow toolchain prefix, so it is checked"
edit_rm "Bash(bash t.sh:*)"
runp --supervisor AI --runner-mode auto
[ "$RC" -ne 0 ] && pass "an absent toolchain prefix stops an AI-supervised run" \
  || die "an absent toolchain prefix passed under auto"
want "missing Bash(bash t.sh:*)" "the absent toolchain prefix is reported missing"

# --- host-command rules as narrow as their commands ------------------------
# A rule's `*` matches any text, spaces included, so a rule ending at a `gh api`
# endpoint reaches every call under it, writes included: no host-command rule,
# shipped or derived from a toolchain.md form, starts at `gh api` or before it.
reaches_gh_api() { local r="${1%%\**}"; r="${r%:}"; case "Bash(gh api" in "$r"*) return 0 ;; esac; return 1; }
wide=$(jq -r '.permissions.allow[] | select(startswith("Bash("))' "$TPL" \
  | while IFS= read -r r; do reaches_gh_api "$r" && printf '%s ' "$r"; done)
[ -z "$wide" ] && pass "no shipped Bash rule reaches gh api" || die "shipped rules reach gh api: $wide"

DOC="$ROOT/skills/dev/companions/toolchain.md"
[ -f "$DOC" ] || die "$DOC not found"
# The REST form of the toolchain.md section headed $1: its fenced line naming
# the installed scripts.
rest_form() {
  awk -v h="## $1" '/^## / { on = ($0 == h); next } on && /^```/ { f = !f; next }
    on && f && index($0, "~/.claude/scripts/") == 1' "$DOC"
}
newfix
{ printf '## Agent toolchain\n\n'
  printf -- '- State-check: `%s`\n' "$(rest_form "State check")"
  printf -- '- CI wait: `%s`\n' "$(rest_form "CI wait")"
  printf -- '- Merge: `%s`\n' "$(rest_form "Merge")"; } > "$PROJ/CLAUDE.md"
sat "$PT" "$PAIR"
runp --supervisor human --runner-mode default
for s in rest-state-check rest-ci-wait rest-merge; do
  want "missing Bash(~/.claude/scripts/$s.sh:*)" "the REST $s line derives the script's path alone"
done
derived=$(printf '%s\n' "$OUT" | tr -s ' ' | sed -n 's/^missing \(Bash(.*)\)$/\1/p')
wide=$(printf '%s\n' "$derived" | while IFS= read -r r; do [ -n "$r" ] && reaches_gh_api "$r" && printf '%s ' "$r"; done)
[ -n "$derived" ] && [ -z "$wide" ] && pass "no rule derived from a REST form reaches gh api" \
  || die "rules derived from the REST forms reach gh api: ${wide:-none derived}"
nowant "Bash(gh *--admin*)" "a toolchain with no gh pr merge line declares no --admin deny"

# `gh pr merge` takes `--admin` after `<n>`, which no allow glob bounds, so its
# rule declares the deny beside it - checked in every mode, written never.
ADMIN='Bash(gh *--admin*)'
merge_fix() {
  newfix; printf '## Agent toolchain\n\n- Merge: `gh pr merge <n> --merge`\n' > "$PROJ/CLAUDE.md"
  sat "$PT" "$1"
  jq '.permissions.allow += ["Bash(gh pr merge:*)"]' "$PT" > "$PT.new" && mv "$PT.new" "$PT"
}
merge_fix "$PAIR"
runp --supervisor human --runner-mode default
[ "$RC" -ne 0 ] && pass "a gh pr merge line without the --admin deny cannot apply" \
  || die "a gh pr merge line without the --admin deny passed"
want "missing $ADMIN" "the absent --admin deny is reported missing"
want "add \"$ADMIN\" to the deny of" "the absent --admin deny's remedy is the user's deny edit"
runp --supervisor human --runner-mode default --apply
! grep -qsF -- '--admin' "$PROJ/.claude/settings.local.json" \
  && pass "--apply writes no --admin deny" || die "--apply wrote the --admin deny"

merge_fix "$(jq -c --arg r "$ADMIN" '. + [$r]' <<< "$PAIR")"
runp --supervisor human --runner-mode default
rc0 "a gh pr merge line beside the --admin deny exits zero"
want "present (project) $ADMIN" "the --admin deny is found in the tier"
want "present (project) Bash(gh pr merge:*)" "the --admin deny does not bar the gh pr merge rule"
nowant "deny reaches it" "the --admin deny swallows no declared allow rule"
printf '{"autoMode":{"classifyAllShell":true}}\n' > "$FIX/user.json"
runp --supervisor AI --runner-mode auto
want "present (project) $ADMIN" "the --admin deny is checked when auto drops the Bash allow rules"

(( fail == 0 )) && echo "preflight-permissions-toolchain.test: ALL OK"
exit $fail
