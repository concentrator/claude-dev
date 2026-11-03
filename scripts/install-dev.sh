#!/usr/bin/env bash
# install-dev.sh - install the DEV toolset into a target .claude.
#
# Usage:
#   install-dev.sh                 install into ~/.claude (global)
#   install-dev.sh --project <p>   install into <p>/.claude (project copy)
#   --minimal                      ship the minimal set (below)
#   --force                        bypass the pre-write project guard
#
# Copies the /dev router + its companions, the bundled dependency skills, the
# seat definitions /dev run dispatches with the rules they and the skills
# cite, the branch-guard + secrets-guard + branch-state + session-brief hooks
# (registered in the target settings.json), the shipped Tier-1 checks with
# their self-tests, the writing conventions and the framework's global
# instructions (dev-instructions.md), each @imported by CLAUDE.md, and -
# on a project install - the maintenance hygiene section when the target doc
# lacks it. Hooks the toolset no longer ships are removed, where they are its
# copies, with their settings entries.
# An install owns only what it copied (scripts/install-manifest.sh): a file
# in the target that is not its copy stays, and is listed. It refuses a
# target inside its own checkout.
# Does NOT ship the user's personal convention rules.
# --minimal serves contributors who work existing plans without /dev: of
# the skills it ships only the delivery files (MINIMAL_DEV), and none of the
# bundled skills, seat definitions or the rules they cite; everything else
# is the same as the full set.
# Idempotent + re-runnable.
set -euo pipefail

SRC="$(git rev-parse --show-toplevel 2>/dev/null)" && [ -f "$SRC/skills/dev/SKILL.md" ] || { echo "install-dev: run from a checkout of the toolset repo" >&2; exit 1; }
command -v jq >/dev/null || { echo "install-dev: jq is required" >&2; exit 1; }
target="$HOME/.claude"; scope="global"; force=0; set=full
while [ $# -gt 0 ]; do
  case "$1" in
    --project) target="${2:?--project needs a path}/.claude"; scope="project"; shift ;;
    --minimal) set=minimal ;;
    --force) force=1 ;;
    *) echo "usage: install-dev.sh [--project <path>] [--minimal] [--force]" >&2; exit 2 ;;
  esac
  shift
done
src_real=$(cd "$SRC" && pwd -P); t=$target; rest=""
while [ ! -d "$t" ]; do rest="/$(basename "$t")$rest"; t=$(dirname "$t"); done
case "$(cd "$t" && pwd -P)$rest/" in
  "$src_real"/*) echo "install-dev: $target is inside the toolset checkout $src_real - install into a target outside it" >&2; exit 1 ;;
esac
. "$(dirname "${BASH_SOURCE[0]}")/install-manifest.sh"

# Pre-write guard (R075): a --project install drops files a later session
# may commit blind alongside unrelated work; refuse a dirty tracked tree
# or a default-branch HEAD so the install rides its own clean branch. A
# non-git target skips the guard; --force bypasses it. The default branch
# is origin/HEAD's basename when set, else whichever of main/master
# exists locally, else no refusal.
proj="${target%/.claude}"
if [ "$scope" = project ] && [ "$force" -eq 0 ] \
   && git -C "$proj" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git -C "$proj" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
    echo "install-dev: $proj has uncommitted changes - commit or stash them, or pass --force" >&2
    exit 1
  fi
  default=$(git -C "$proj" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  default=${default#origin/}
  if [ -z "$default" ]; then
    for b in main master; do
      if git -C "$proj" show-ref -q --verify "refs/heads/$b"; then default=$b; break; fi
    done
  fi
  cur=$(git -C "$proj" branch --show-current 2>/dev/null || true)
  if [ -n "$default" ] && [ "$cur" = "$default" ]; then
    echo "install-dev: $proj is on its default branch '$default' - switch to a new branch, or pass --force" >&2
    exit 1
  fi
fi

BUNDLED="systematic-debugging dispatching-parallel-agents"
# The trees a full install ships whole; an install into a target with no
# manifest also judges each file under them that it does not ship
# (install-manifest.sh).
TREES="skills/dev agents $(printf 'skills/%s ' $BUNDLED)"
CITED_RULES="code-comments.md claude-md.md"
RETIRED="dev-handoff-nudge.sh dev-precompact-state.sh dev-context-fill.sh"
# The template is the permission pre-flight's input, read at run time
# (scripts/preflight-permissions.sh), not documentation.
MINIMAL_DEV="finish.md git-workflow.md companions/declarations.md companions/toolchain.md companions/untracked-claude.md companions/secrets.md companions/auto-permissions.template.json"

mkdir -p "$target"

# 1. the /dev router + companions (minimal: the delivery files only, no router)
if [ "$set" = full ]; then
  ship_tree skills/dev
else
  for f in $MINIMAL_DEV; do ship "skills/dev/$f"; done
fi

# 2. bundled dependency skills (the companions reference these by name), the
#    seat definitions /dev run dispatches, and the rules the seats and the
#    skills cite
if [ "$set" = full ]; then
  for s in $BUNDLED; do ship_tree "skills/$s"; done
  ship_tree agents
  for f in $CITED_RULES; do ship "rules/$f"; done
fi

# 3. hooks: copy + register the branch-guard and the secrets guard
#    (PreToolUse) and the branch-state line (UserPromptSubmit)
#    (idempotent; preserve everything else in settings.json).
#    A hook command runs in the session's cwd, so the project form is
#    "$CLAUDE_PROJECT_DIR"/.claude/hooks/<name> (the root Claude Code sets
#    for every hook) and `~` expands anywhere; an entry in the relative
#    form `.claude/hooks/<name>`, which resolves only from the project
#    root, is replaced, and so is an entry whose matcher the toolset has
#    since changed.
if [ "$scope" = global ]; then hp="~/.claude/hooks"; else hp='"$CLAUDE_PROJECT_DIR"/.claude/hooks'; fi
settings="$target/settings.json"
[ -f "$settings" ] || echo '{}' > "$settings"

# edit_settings <jq filter> [jq args]: settings.json is rewritten only when
# the filter changes its value, so a file already holding every toolset entry
# keeps its bytes. `unhook(f)` drops the commands f selects, and an entry
# only when that empties it.
edit_settings() {
  local filter=$1 tmp; shift; tmp="$(mktemp)"
  if jq "$@" 'def unhook(f): map(if any(.hooks[]?; f) then .hooks |= map(select(f | not)) | select(.hooks | length > 0) else . end);
      . as $in | '"$filter"' | if . == $in then empty else . end' "$settings" > "$tmp"; then
    if [ -s "$tmp" ]; then mv "$tmp" "$settings"; else rm -f "$tmp"; fi
  else
    rm -f "$tmp"; echo "install-dev: failed to update $settings (invalid JSON?)" >&2; exit 1
  fi
}

# register <event> <entries> <hook>: ship the hook, drop its relative-form
# entries, and add <entries> for it when no entry of <event> runs it.
register() {
  ship "hooks/$3" x
  edit_settings '($add | map(.matcher)) as $ms
    | .hooks[$ev] = ((.hooks[$ev] // []) | unhook(.command == $old)
      | map(if (.matcher as $m | $ms | index([$m])) then . else ([.] | unhook(.command == $cmd))[] end))
    | .hooks[$ev] as $now
    | .hooks[$ev] += [$add[] | .matcher as $m
      | select(any($now[]; .matcher == $m and any(.hooks[]?; .command == $cmd)) | not)]' \
    --arg ev "$1" --arg cmd "$hp/$3" --arg old ".claude/hooks/$3" \
    --argjson add "$(jq -cn --arg cmd "$hp/$3" "$2")"
}
register_hook() {   # $1 = hook script basename; PreToolUse, file edits and Bash
  register PreToolUse '[{matcher: "Write|Edit|NotebookEdit"}, {matcher: "Bash"}] | map(.hooks = [{type: "command", command: $cmd}])' "$1"
}
register_state_hook() {   # $1 = hook script basename; UserPromptSubmit, no matcher
  register UserPromptSubmit '[{hooks: [{type: "command", command: $cmd}]}]' "$1"
}
register_brief_hook() {   # $1 = hook script basename; SessionStart, every start the hook reads
  register SessionStart '[{matcher: "compact|resume|clear|startup", hooks: [{type: "command", command: $cmd}]}]' "$1"
}

register_hook dev-branch-guard.sh
register_hook dev-secrets-guard.sh
register_state_hook dev-branch-state.sh
register_brief_hook dev-session-brief.sh
# The secrets guard's predicate lives beside it (sourced, not registered).
ship hooks/secret-patterns.sh
ship hooks/dev-hook-once.sh
# Retired hooks (RETIRED): an install over an earlier one removes each
# script that is its copy (install-manifest.sh) and every settings entry, on
# any event, that runs one; an event left with no entry is dropped.
edit_settings 'def retired: (.command // "") as $c | any($names | split(" ")[]; . as $n | $c | endswith("/" + $n));
  if (.hooks | type) == "object" then .hooks |= with_entries(
    if any(.value[]?.hooks[]?; retired) then .value |= unhook(retired) | select(.value | length > 0) else . end)
  else . end' --arg names "$RETIRED"

# 4. shipped Tier-1 checks - the ones with no dependency on this repo's
#    own layout; adopters wire them into their CI (the batch-tags gate
#    enforces locally, e.g. a pre-push hook - its CI run reports a
#    skip). Accretion, batch-tags, plan-text and archival ship their
#    self-tests; the first two are tuned per project (the MARKERS list,
#    the ref namespaces), and the self-test validates that edit. Adopter
#    tuning survives a re-run: the code-size allowlist is written only
#    when absent, and a tuned check is the adopter's, left in place and
#    listed (install-manifest.sh). The permission pre-flight ships beside
#    them because skills/dev/run.md § Pre-flight names it: an adopter's runner
#    would otherwise cite a script its checkout lacks. The REST state check,
#    CI wait and merge ship for the same reason: skills/dev/companions/
#    toolchain.md gives them as the declared commands of a host whose CLI has
#    REST only.
mkdir -p "$target/scripts/ci"
for f in check-code-size.sh check-no-em-dash.sh check-accretion.sh check-batch-tags.sh check-plan-text.sh \
         check-archival.sh; do
  ship "scripts/ci/$f" x
done
ship scripts/ci/branch-diff.sh
ship scripts/preflight-permissions.sh x
ship scripts/rest-ci-wait.sh x
ship scripts/rest-state-check.sh x
ship scripts/rest-merge.sh x
for f in check-accretion.test.sh check-batch-tags.test.sh check-plan-text.test.sh check-archival.test.sh \
         preflight-permissions.test.sh preflight-permissions-toolchain.test.sh; do
  ship "scripts/test/$f"
done
if [ ! -f "$target/scripts/ci/code-size-allow.txt" ]; then
  cat > "$target/scripts/ci/code-size-allow.txt" <<'EOF'
# check-code-size.sh exemptions: one tracked path per line; text after `#` is
# the reason. Exempts a path from both the file-size and function-size checks.
EOF
fi

# 5. writing conventions and global instructions: ship writing.md and
#    dev-instructions.md + @import each from the target CLAUDE.md, and the
#    path-scoped DEV-artifact writing rule
#    (append-only + idempotent; never clobbers an existing CLAUDE.md).
IMPORTS="writing.md dev-instructions.md"
for f in $IMPORTS; do ship "$f"; done
ship rules/writing-artifacts.md
install_shipped
claudemd="$target/CLAUDE.md"
for f in $IMPORTS; do
  grep -qxF "@$f" "$claudemd" 2>/dev/null || printf '\n@%s\n' "$f" >> "$claudemd"
done

# 6. committability: for a project install, allowlist installed paths that the
# target repo's .gitignore excludes (idempotent), so they can be committed.
if [ "$scope" = project ] && git -C "$proj" rev-parse --show-toplevel >/dev/null 2>&1; then
  repo="$(git -C "$proj" rev-parse --show-toplevel)"; gi="$repo/.gitignore"
  for p in ".claude/skills/" ".claude/agents/" ".claude/hooks/" ".claude/scripts/" ".claude/writing.md" ".claude/dev-instructions.md" ".claude/rules/" ".claude/CLAUDE.md" ".claude/settings.json" ".claude/MAINTENANCE.md" ".claude/$MANIFEST"; do
    git -C "$repo" check-ignore -q "${p%/}" 2>/dev/null || continue   # not ignored → skip
    grep -qxF "!$p" "$gi" 2>/dev/null && continue                      # already allowlisted
    printf '!%s\n' "$p" >> "$gi"
  done
  pfx=$(git -C "$target" rev-parse --show-prefix); gates="check-plan-text.sh check-code-size.sh"; tier=""; claude=""
  for key in 'Test (fast)' 'Test'; do
    for f in "$repo/CLAUDE.md" "$repo/.claude/CLAUDE.md"; do
      if [ -z "$tier" ] && tier=$(grep -m1 -n "^- $key:" "$f" 2>/dev/null); then claude=$f; fi
    done
  done
  if [ -z "$tier" ]; then
    echo "install-dev: no Test (fast): or Test: line in $repo/CLAUDE.md or $repo/.claude/CLAUDE.md - add to the § Agent toolchain of one: - Test (fast): <fast tier>$(for g in $gates; do printf ', then `bash %sscripts/ci/%s`' "$pfx" "$g"; done)"
  else for g in $gates; do
    if end=$(awk -v n="${tier%%:*}" -v g="$g" 'NR > n && !/^  / { exit } NR >= n { e = NR; h = h || index($0, g) } END { if (!h) print e }' "$claude") && [ -n "$end" ]; then
      tmp="$(mktemp)"; awk -v n="$end" -v add=", then \`bash ${pfx}scripts/ci/$g\`" 'NR == n { if (match($0, /.*`/)) $0 = substr($0, 1, RLENGTH) add substr($0, RLENGTH + 1); else { sub(/\.$/, ""); $0 = $0 add } } 1' "$claude" > "$tmp"
      cat "$tmp" > "$claude"
    fi
  done; fi
fi

# 8. maintenance: seed the hygiene section - the cleanup rules for the
#    toolset's own by-products (closed plans, allow-list growth) - into
#    the project doc when its heading is absent; the heading is the
#    marker, so an adopter's tuned copy is never touched.
#    The global target ~/.claude is no project: the toolset's own hygiene
#    is this repo's MAINTENANCE.md § Routine, the superset, so global
#    installs seed nothing.
seeded=""
if [ "$scope" = project ]; then
  m="$target/MAINTENANCE.md"
  if ! grep -q '^## Session and planning hygiene' "$m" 2>/dev/null; then
    if [ -f "$m" ]; then
      [ -z "$(tail -c1 "$m")" ] || printf '\n' >> "$m"   # terminate an unterminated last line
      printf '\n' >> "$m"
    else
      printf '# Maintenance\n\n' > "$m"
    fi
    cat >> "$m" <<'EOF'
## Session and planning hygiene

DEV-toolset by-products age out on a cadence: detect, report, repair - and
never silently delete something you didn't create.

| Target | Check | Cadence |
|---|---|---|
| the `Plans:` tree (`CLAUDE.md § Layout`) | orphaned or closed plan, findings, requirements and batch files; empty initiative dirs | monthly |
| `.claude/settings.json` + any `settings.local.json` | allow-list mess: one-off, dead or overlapping rules | weekly |
| repo root and `.claude/` | stray temp or build artifacts | weekly |
EOF
    seeded="$m"
  fi
fi

echo "install-dev: DEV toolset ($set) installed into $target ($scope)"
echo "install-dev: Tier-1 checks in $target/scripts/ci/ (check-code-size.sh, check-no-em-dash.sh, check-accretion.sh, check-batch-tags.sh, check-plan-text.sh, check-archival.sh)"
echo "install-dev: self-tests in $target/scripts/test/ - wire checks and self-tests into your CI; the /dev run's permission pre-flight is $target/scripts/preflight-permissions.sh"
list_kept
if [ -n "$seeded" ]; then echo "install-dev: maintenance hygiene section seeded into $seeded"; fi
if [ -n "${repo:-}" ]; then echo "install-dev: your CI must run the fast tier (the Test (fast): or Test: line of ${claude:-$repo/CLAUDE.md or $repo/.claude/CLAUDE.md}) - no CI config was edited"; fi
