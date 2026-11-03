#!/usr/bin/env bash
# Tier-1 cap check: CLAUDE.md / DESIGN.md / SKILL.md / dev mode-file size
# limits. Caps per rules/skills.md § Size and skills/dev/layout.md; this
# repo's CLAUDE.md and dev-instructions.md, the global instructions, are held
# to 100 lines, inside rules/claude-md.md's general 200. SKILL body = file minus YAML frontmatter (skills.md caps are on
# body). Mode files are measured in lines and line length, never words:
# a word count does not measure a document (R040-T025).
# Skill class lists below mirror skills.md § Size; new skills default to
# the general 300-word cap. A doc under the docs path CLAUDE.md § Layout
# declares holds to 300 lines (skills/dev/companions/documentation.md).
set -euo pipefail
export LC_ALL=C.UTF-8   # ${#line} counts characters, not bytes
h="$(dirname "${BASH_SOURCE[0]}")/branch-diff.sh"
{ [ -r "$h" ] && . "$h"; } \
  || { echo "check-caps: cannot load branch-diff.sh"; exit 1; }
cd "$(git rev-parse --show-toplevel)"

fail=0
report() { echo "CAP: $1"; fail=1; }

orchestrators=" dev "
reference=" dispatching-parallel-agents systematic-debugging "

D=$(sed -n 's/^- Docs: *//p' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1 || true)
D=${D:-docs}; D=${D%/}

base=$(branch_base) || base=
old=$(mktemp); trap 'rm -f "$old"' EXIT

lines_of() { wc -l < "$1" | tr -d ' '; }
words_of() { wc -w < "$1" | tr -d ' '; }
body_words() { awk 'NR==1&&/^---/{f=1;next} f&&/^---/{f=0;next} !f' "$1" | wc -w | tr -d ' '; }
description_words() { sed -n 's/^description: //p' "$1" | wc -w | tr -d ' '; }
mode_lines() { awk 'END { print NR }' "$1"; }

over() {
  local now was
  now=$("$4" "$1")
  : > "$old"
  if [ -n "$2" ]; then git show "$base:$2" > "$old" 2>/dev/null || : > "$old"; fi
  was=$("$4" "$old")
  if (( now > $3 && was <= $3 )); then echo "$now"; fi
}

long_added() {
  local rec n line t long=""
  branch_added "$base" ":(literal)$1" ${2:+":(literal)$2"} | while IFS= read -r rec; do
    rec=${rec#*$'\t'}; n=${rec%%$'\t'*}; line=${rec#*$'\t'}
    t="${line#"${line%%[![:space:]]*}"}"
    [ "${t:0:1}" = '|' ] && continue
    [ -n "$long" ] || (( ${#line} <= 80 )) || { long="line $n: ${#line} characters > 80"; echo "$long"; }
  done
}

while IFS=$'\t' read -r _ f from; do
  case "$f" in
    CLAUDE.md|dev-instructions.md)
      n=$(over "$f" "$from" 100 lines_of); [ -z "$n" ] || report "$f $n lines > 100" ;;
    DESIGN.md)
      n=$(over "$f" "$from" 1000 words_of); [ -z "$n" ] || report "DESIGN.md $n words > 1000" ;;
    skills/*/SKILL.md)
      key=$(basename "$(dirname "$f")")
      cap=300
      case "$orchestrators" in *" $key "*) cap=400 ;; esac
      case "$reference"     in *" $key "*) cap=1500 ;; esac
      n=$(over "$f" "$from" "$cap" body_words); [ -z "$n" ] || report "$f body $n words > $cap"
      n=$(over "$f" "$from" 12 description_words); [ -z "$n" ] || report "$f description $n words > 12" ;;
    # R-021: skills/dev/ mode files (read on demand by the dev router) - 350
    # lines, 80 characters a line; a table row cannot wrap, so it is exempt from
    # the length ceiling. SKILL.md handled above; companions/ are exempt.
    "$D"/archive/*) ;;
    "$D"/*.md)
      n=$(over "$f" "$from" 300 lines_of); [ -z "$n" ] || report "$f $n lines > 300" ;;
    skills/dev/*/*) ;;
    skills/dev/*.md)
      n=$(over "$f" "$from" 350 mode_lines); [ -z "$n" ] || report "$f $n lines > 350"
      long=$(long_added "$f" "$from"); [ -z "$long" ] || report "$f $long" ;;
  esac
done < <(branch_changed "$base")

(( fail == 0 )) && echo "check-caps: OK"
exit $fail
