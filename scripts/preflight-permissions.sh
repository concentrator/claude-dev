#!/usr/bin/env bash
# preflight-permissions.sh - the /dev run's permission pre-flight
# (skills/dev/companions/seat-permissions.md; skills/dev/run.md § Pre-flight).
#
# Resolves the declared permission set - the rules of
# companions/auto-permissions.template.json, the commands of the project's
# CLAUDE.md § Agent toolchain and the deny beside a `gh pr merge` one - against
# the three settings tiers a session reads, and prints one report whose every
# line names the tier that satisfied the rule, so a report that read one tier
# cannot pass as a full answer. Only the rules binding in the runner's mode are
# resolved. Every tier is read from its working-tree file, which is what the
# session's own permission check reads; git state enters one check only, the
# mode-key comparison, which needs a tracked value to compare against.
# --apply merges the missing allow rules into the local tier, preserving its
# other keys; it writes no deny rule, no mode key and nothing in
# ~/.claude.json, and a cannot-apply verdict writes nothing at all.
# Exit 0 the report is clean or, under Supervisor: human, its only gaps are
# missing allow rules; 1 a gap or a cannot-apply; 2 a usage error.
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
TEMPLATE="$(cd "$(dirname "$SELF")" && pwd -P)/../skills/dev/companions/auto-permissions.template.json"

lines=""; remedies=""; missing_list=""; cannot_n=0; missing_n=0
u_allow=""; p_allow=""; l_allow=""; u_deny=""; p_deny=""; l_deny=""
u_mode=""; p_mode=""; l_mode=""

usage() { printf 'usage: %s --project <path> --supervisor <human|AI>\n       --runner-mode <auto|acceptEdits|default|unknown> [--apply]\n' "$SELF"; }

say()     { lines="$lines$1"$'\t'"$2"$'\n'; }
remedy()  { remedies="$remedies  $1"$'\n'; }
blocked() { cannot_n=$((cannot_n + 1)); say "cannot apply: $1" "$2"; }

# A precondition failed: no rule is resolved and nothing is written.
stop() {
  printf '%-20s %s\n' "cannot apply: $1" "$2"
  [ -n "${3:-}" ] && printf 'remedy:\n  %s\n' "$3"
  exit 1
}

# Does the tier rule $1 reach the declared rule $2? Its exact string does, and
# so does a rule whose wildcards all trail and whose literal prefix - its text
# before the first wildcard, a trailing `:` dropped - prefixes $2's: so
# `Edit(//<root>/**)` covers a declared child path and `Bash(git:*)` covers
# `Bash(git log:*)`, while `Bash(gh *--admin*)` reaches only its own string.
covers() {
  local t="${1#*\*}" a="${1%%\**}" b="${2%%\**}"
  [ "$1" = "$2" ] && return 0
  [ "${t//\*/}" = ")" ] || return 1
  case "${b%:}" in "${a%:}"*) return 0 ;; esac
  return 1
}

# The first tier reaching rule $1, or nothing. $2 selects the list and the
# match: `allow` covers, `deny` is the exact string a declared deny needs,
# `denies` covers - a tier deny wide enough to swallow a declared allow rule.
tier_of() {
  local t v r
  for t in user project local; do
    v="${t:0:1}_allow"; [ "$2" = allow ] || v="${t:0:1}_deny"
    while IFS= read -r r; do
      [ -n "$r" ] || continue
      case "$2" in
        deny) [ "$r" = "$1" ] || continue ;;
        *)    covers "$r" "$1" || continue ;;
      esac
      printf '%s' "$t"; return 0
    done <<< "${!v}"
  done
  return 1
}

tier_path() { case "$1" in user) printf '%s' "$UT" ;; project) printf '%s' "$PT" ;; *) printf '%s' "$LT" ;; esac; }
tier_list() { [ -f "$1" ] && jq -r ".permissions.$2[]? // empty" "$1" 2>/dev/null; }
tier_mode() { [ -f "$1" ] && jq -r '.permissions.defaultMode // empty' "$1" 2>/dev/null; }

# The mode-key half of the mode assertion, for the tiers that exist: the
# tier's working-tree value against its committed one. Every failure to
# reach a committed value - no repository, an untracked file, a file staged
# but never committed, whose `show` exits non-zero - is `untracked`, which
# passes: there is no tracked value to have drifted from.
mode_key() {
  local f cur top rel trk
  f=$(tier_path "$1"); [ -f "$f" ] || return 0
  cur=$(tier_mode "$f")
  f="$(cd "$(dirname "$f")" && pwd -P)/$(basename "$f")"
  top=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null)
  rel="${f#"$top"/}"
  if [ -z "$top" ] || ! git -C "$top" ls-files --error-unmatch "$rel" >/dev/null 2>&1 \
     || ! trk=$(git -C "$top" show "HEAD:$rel" 2>/dev/null); then
    say untracked "mode key ($1): ${cur:-(none)}"
    return 0
  fi
  trk=$(printf '%s' "$trk" | jq -r '.permissions.defaultMode // empty' 2>/dev/null)
  if [ "$cur" = "$trk" ]; then
    say unchanged "mode key ($1): ${cur:-(none)}"
  else
    blocked "the mode key drifted from its tracked value" \
      "mode key ($1): ${cur:-(none)}, tracked ${trk:-(none)}"
  fi
}

# One declared deny string: satisfied only by its exact string in a tier's
# deny. --apply writes no deny, so the remedy is the user's own tier edit.
check_deny() {
  local t
  if t=$(tier_of "$1" deny); then say "present ($t)" "$1"; return; fi
  cannot_n=$((cannot_n + 1)); say missing "$1"
  remedy "add \"$1\" to the deny of $PT"
}

# Which carve-out pattern the tiers are on, and the rules it declares
# (companions/toolchain.md § Permission carve-out). A blanket deny in any tier
# is pattern 2; otherwise pattern 1, whose deny pair needs the default branch
# pattern 2 never asks for, and whose allow block is one push rule per prefix.
carve_out() {
  local t def p
  if t=$(tier_of "Bash(git push:*)" deny); then
    if [ "$supervisor" = AI ]; then
      blocked "nobody can answer pattern 2's prompt under Supervisor: AI" \
        "carve-out pattern 2"
      remedy "narrow the $t tier's deny to pattern 1 (companions/toolchain.md)"
    else
      say ok "carve-out pattern 2"
    fi
    check_deny "Bash(git push:*)"
    return
  fi
  def=$(git -C "$project" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  def="${def#origin/}"
  [ -n "$def" ] || def=$(git -C "$project" config init.defaultBranch 2>/dev/null)
  if [ -z "$def" ]; then
    blocked "the default branch does not resolve, so pattern 1 has no string to check" \
      "carve-out pattern 1"
    remedy "git -C $project remote set-head origin --auto"
    return
  fi
  say ok "carve-out pattern 1 (default branch $def)"
  check_deny "Bash(git push origin $def:*)"
  check_deny "Bash(git push --force:*)"
  for p in batch doc feat fix refactor mnt test plan; do declared="$declared"$'\n'"Bash(git push -u origin $p/*)"; done
}

# One declared allow rule.
resolve() {
  local t
  if t=$(tier_of "$1" denies); then blocked "the $t tier's deny reaches it" "$1"; return; fi
  if t=$(tier_of "$1" allow); then say "present ($t)" "$1"; return; fi
  say missing "$1"
  missing_list="$missing_list$1"$'\n'; missing_n=$((missing_n + 1))
}

toolchain_rules() {
  local f s files=()
  for f in "$project/CLAUDE.md" "$project/.claude/CLAUDE.md"; do [ -f "$f" ] && files+=("$f"); done
  [ "${#files[@]}" -gt 0 ] || return 0
  while IFS= read -r s; do
    case "$s" in -*) continue ;; *" "*) ;; *) continue ;; esac
    s="${s%%<*}"; s="${s%"${s##*[![:space:]]}"}"
    [ -n "$s" ] && printf 'Bash(%s:*)\n' "$s"
  done <<< "$(awk 'FNR == 1 { f = 0; b = 0 } /^## Agent toolchain/ { f = 1; next } f && /^## / { f = 0; b = 0 }
    f && /^[[:space:]]*-[[:space:]]/ { b = 1 } f && /^([^[:space:]-]|$)/ { b = 0 }
    f && b { n = split($0, a, "`"); for (i = 2; i <= n; i += 2) if (a[i] != "") print a[i] }' "${files[@]}")"
}

# Merge the missing allow rules into the local tier and restate their lines.
apply_rules() {
  local add cur tmp l st sub out=""
  add=$(printf '%s' "$missing_list" | jq -R -s 'split("\n") | map(select(length > 0))') || return 1
  cur='{}'; [ -f "$LT" ] && cur=$(cat "$LT")
  tmp=$(mktemp "$LT.XXXXXX") || return 1
  printf '%s' "$cur" | jq --argjson add "$add" \
    '.permissions.allow = ((.permissions.allow // []) + $add)' > "$tmp" \
    && mv "$tmp" "$LT" && chmod 644 "$LT" || { rm -f "$tmp"; return 1; }
  while IFS= read -r l; do
    st="${l%%$'\t'*}"; sub="${l#*$'\t'}"
    if [ "$st" = missing ]; then
      case $'\n'"$missing_list" in *$'\n'"$sub"$'\n'*) st="applied (local)" ;; esac
    fi
    out="$out$st"$'\t'"$sub"$'\n'
  done <<< "$(printf '%s' "$lines")"
  lines="$out"
}

report() {
  local l
  while IFS= read -r l; do
    printf '%-20s %s\n' "${l%%$'\t'*}" "${l#*$'\t'}"
  done <<< "$(printf '%s' "$lines")"
  [ -n "$remedies" ] && printf 'remedy:\n%s' "$remedies"
  return 0
}

# --- arguments -----------------------------------------------------------
project=""; supervisor=""; runner_mode=""; apply=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project)     project="${2:-}"; shift; shift ;;
    --supervisor)  supervisor="${2:-}"; shift; shift ;;
    --runner-mode) runner_mode="${2:-}"; shift; shift ;;
    --apply)       apply=1; shift ;;
    -h | --help)   usage; exit 0 ;;
    *) printf 'preflight-permissions: unknown argument %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$project" ] || { usage >&2; exit 2; }
case "$supervisor" in human | AI) ;; *) usage >&2; exit 2 ;; esac
case "$runner_mode" in auto | acceptEdits | default | unknown) ;; *) usage >&2; exit 2 ;; esac

# --- preconditions: a pre-flight that cannot read the tiers stops the run --
command -v jq >/dev/null 2>&1 || stop "jq is absent" "tier read" "install jq"
project=$(cd "$project" 2>/dev/null && pwd -P) || project=""
[ -n "$project" ] || stop "--project does not resolve to a directory" "arguments"
printf 'preflight-permissions: %s, supervisor %s, runner mode %s\n' \
  "$project" "$supervisor" "$runner_mode"

CJ="${PREFLIGHT_CLAUDE_JSON:-$HOME/.claude.json}"
[ "$(jq -r --arg p "$project" '.projects[$p].hasTrustDialogAccepted // false' \
  "$CJ" 2>/dev/null)" = true ] \
  || stop "the workspace is not trusted, so its project-tier allow rules are ignored" \
    "workspace trust" "open $project in Claude Code and accept the trust prompt"

CDIR="$project/.claude"
[ -d "$CDIR" ] || stop "$CDIR is absent" "local tier" "mkdir -p $CDIR"
UT="${PREFLIGHT_USER_SETTINGS:-$HOME/.claude/settings.json}"
PT="$CDIR/settings.json"
LT="$CDIR/settings.local.json"
w="$CDIR"; [ -f "$LT" ] && w="$LT"
[ -w "$w" ] || stop "$w is not writable, so --apply could not close a gap" \
  "local tier" "chmod u+w $w"
for f in "$UT" "$PT" "$LT"; do
  [ -f "$f" ] || continue
  jq -e . "$f" >/dev/null 2>&1 || stop "$f is not valid JSON" "tier read" "fix the file"
done
declared=$(jq -r --arg p "${project#/}" --arg h "${HOME#/}" '.permissions.allow[] |
  gsub("__PROJECT_DIR__"; $p) | gsub("__HOME__"; $h)' "$TEMPLATE"); rc=$?
# jq aborts a filter error after emitting the earlier rules, so the status and
# not an empty $declared is what tells a truncated read from a whole one.
[ "$rc" -eq 0 ] && [ -n "$declared" ] || stop "the permission template resolved no declared set (jq exit $rc)" "$TEMPLATE" "read jq's message above; reinstall the toolset (scripts/install-dev.sh) if the template is damaged"
say ok "workspace trust"

u_allow=$(tier_list "$UT" allow); u_deny=$(tier_list "$UT" deny); u_mode=$(tier_mode "$UT")
p_allow=$(tier_list "$PT" allow); p_deny=$(tier_list "$PT" deny); p_mode=$(tier_mode "$PT")
l_allow=$(tier_list "$LT" allow); l_deny=$(tier_list "$LT" deny); l_mode=$(tier_mode "$LT")

# --- the mode assertion and the never-list -------------------------------
if [ "$supervisor" = AI ]; then
  if [ "$runner_mode" = auto ]; then
    say ok "permission mode auto"
  else
    blocked "the runner's permission mode is '$runner_mode', not auto" "permission mode"
  fi
else
  say ok "permission mode (not asserted under Supervisor: human)"
fi
for t in user project local; do mode_key "$t"; done
nv=""
for t in user project local; do
  v="${t:0:1}_mode"
  case "${!v}" in
    bypassPermissions | dontAsk)
      blocked "the $t tier sets defaultMode ${!v}" "never-list"; nv=1 ;;
  esac
done
[ -n "$nv" ] || say ok "never-list (no bypassPermissions, no dontAsk)"

# --- the carve-out pattern, its deny set, then the allow rules ------------
carve_out
tc_rules=$(toolchain_rules)
# No allow glob bounds a `gh pr merge` rule's flags: a deny bars `--admin`.
case $'\n'"$tc_rules" in *$'\n''Bash(gh pr merge'*) check_deny 'Bash(gh *--admin*)' ;; esac

while IFS= read -r r; do
  [ -n "$r" ] && resolve "$r"
done <<< "$(printf '%s\n' "$declared" | grep -v '^Bash(')"

# Auto drops every Bash allow rule only under the user tier's classifyAllShell.
if [ "$runner_mode" = auto ] && [ "$(jq -r '.autoMode.classifyAllShell' "$UT" 2>/dev/null)" = true ]; then
  say "dropped (auto)" "Bash allow rules (the user tier sets autoMode.classifyAllShell)"
else
  while IFS= read -r r; do
    [ -n "$r" ] && resolve "$r"
  done <<< "$(printf '%s\n%s\n' "$(printf '%s\n' "$declared" | grep '^Bash(')" \
              "$tc_rules" | awk 'NF && !seen[$0]++')"
fi

# --- apply, report, verdict ----------------------------------------------
if [ "$cannot_n" -eq 0 ] && [ "$missing_n" -gt 0 ]; then
  if [ "$apply" -eq 1 ]; then
    apply_rules || blocked "the write to $LT failed" "local tier"
  else
    remedy "$SELF --project $project --supervisor $supervisor --runner-mode $runner_mode --apply"
  fi
fi
report
[ "$cannot_n" -eq 0 ] || exit 1
# Under Supervisor: human the user answers the prompt a missing allow rule
# raises, so the gap is reported and halts no run.
[ "$missing_n" -eq 0 ] || [ "$apply" -eq 1 ] || [ "$supervisor" = human ] || exit 1
exit 0
