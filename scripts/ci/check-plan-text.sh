#!/usr/bin/env bash
# Tier-1 plan-text gate on the plan files a branch changes, archive excluded:
# ROADMAP entries, requirements.md, tasks.md and branch plans stay short and
# stable (skills/dev/templates.md). Fails on links, ISO dates, #NNN refs,
# commit hashes, ids of another initiative in requirements.md (ROADMAP and
# tasks.md cite them by id), oversize entries, an added *.findings.md, and a
# normal plan's report entry over one line. A plan whose header lacks
# `mode: normal` also takes the strict checks: a report checkbox without an
# Evidence: line, a plan without its task report, an added plan without
# ## Claims or ## Proven, a plan's claim its task report's ## Claims does not
# repeat, and a done item's claim entry with an empty field.
set -uo pipefail
h="$(dirname "${BASH_SOURCE[0]}")/branch-diff.sh"
{ [ -r "$h" ] && . "$h"; } \
  || { echo "check-plan-text: cannot load branch-diff.sh"; exit 1; }
cd "$(git rev-parse --show-toplevel)"

P=$(sed -n 's/^- Plans: *//p' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1 || true)
P=${P:-dev/plans}
P=${P%/}
fail=0

base=$(branch_base) || { echo "check-plan-text: SKIP (no default branch)"; exit 0; }
new=$(mktemp); old=$(mktemp); blob=$(mktemp); blob2=$(mktemp)
trap 'rm -f "$new" "$old" "$blob" "$blob2"' EXIT
pairs=

scan() {
  awk -v f="$2" -v own="$3" -v mode="$4" '
    function bad(n, why, key) { printf "PLAN-TEXT: %s:%d: %s\t%s\t%s\n", f, n, why, why, key }
    function check(n, s,   t, id) {
      if (s ~ /https?:\/\// || s ~ /\]\(/) bad(n, "link", s)
      if (s ~ /20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) bad(n, "date", s)
      if (s ~ /(^|[^A-Za-z0-9&])#[0-9]+/) bad(n, "#NNN ref", s)
      t = s
      while (match(t, /[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+/)) {
        id = substr(t, RSTART, RLENGTH)
        if (id ~ /[0-9]/ && id ~ /[a-f]/) { bad(n, "commit hash", s); break }
        t = substr(t, RSTART + RLENGTH)
      }
      if (mode != "req") return
      t = s
      while (match(t, /R-?[0-9][0-9][0-9]/)) {
        id = substr(t, RSTART, RLENGTH); sub(/-/, "", id)
        if (id != own) { bad(n, "id of another initiative: " id, s); break }
        t = substr(t, RSTART + RLENGTH)
      }
    }
    BEGIN { max = mode == "plan" ? 6 : 3 }
    function open_entry() { start = NR; len = 0; first = $0; sub(/^- \[.\]/, "- [ ]", first) }
    function close_entry() { if (start && len > max) bad(start, (mode == "plan" ? "item" : "entry") " over " max " lines", first); start = 0 }
    mode == "roadmap" {
      if ($0 ~ /^- \[[ x]\] R-?[0-9][0-9][0-9]/) {
        close_entry(); active = 1; open_entry()
      } else if ($0 !~ /^      / && $0 !~ /^  [^ ]/) { close_entry(); active = 0 }
      if (active) { len++; check(NR, $0) }
      next
    }
    mode == "tasks" || mode == "plan" {
      if ($0 ~ /^- \[/) { close_entry(); open_entry() }
      else if ($0 !~ /^  /) close_entry()
      if (start) len++
    }
    mode == "plan" { next }
    mode == "req" && match($0, /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+\[[ x]\]/) {
      bad(NR, "checkbox", substr($0, 1, RLENGTH - 2) " " substr($0, RLENGTH))
    }
    { check(NR, $0) }
    END {
      close_entry()
      if (mode == "req" && NR > 40) bad(NR, "requirements.md over 40 lines", "")
    }' "$1"
}

report() {
  awk -v f="$2" '
    function close_box() { if (box && !ev) printf "PLAN-TEXT: %s:%d: finding without Evidence: observed|test|contract\tevidence\t%s\n", f, box, first; box = 0 }
    /^- \[[ x]\]/ { close_box(); box = NR; ev = 0; first = $0; sub(/^- \[.\]/, "- [ ]", first); next }
    box && /^  +Evidence: (observed|test|contract) / { ev = 1; next }
    box && !/^  / { close_box() }
    END { close_box() }' "$1"
}

oneline() {
  awk -v f="$2" '
    /^- / { at = NR; first = $0; told = 0; next }
    at && /^  +[^ ]/ && !told { printf "PLAN-TEXT: %s:%d: report entry over 1 line\toneline\t%s\n", f, at, first; told = 1; next }
    !/^  / { at = 0 }' "$1"
}

normal() { awk 'NR == 1 && /^---$/ { h = 1; next } h && /^---$/ { exit } h && /^mode: *normal *$/ { n = 1 } END { exit !n }' "$1" 2>/dev/null; }

backlog() {
  awk -v f="$2" '
    function over() { if (!told) printf "PLAN-TEXT: %s:%d: backlog line over 1 line\tbacklog\t%s\n", f, at, first; told = 1 }
    /^- \[/ { task = 1; ctx = ""; ub = 0; next }
    task && /^  / { next }
    { task = 0 }
    !/[^ \t]/ { ctx = ""; next }
    /^(#|Why:)/ { ctx = /^Why:/ ? "why" : ""; ub = 0; next }
    ctx == "why" { next }
    (ctx == "line" && !/^[-*] /) || (ub && /^[ \t]/) { over(); ctx = "line"; next }
    { at = NR; first = $0; told = 0; ub = /^[-*] /; ctx = "line" }' "$1"
}

claims() {
  awk -v fp="$3" -v fr="${3%.md}.report.md" '
    function flush(  x) {
      if (k != "" && inplan) { line[k] = start; item[k] = it; kind[k] = kd }
      else if (k != "") { got[k] = start; for (x in fv) val[k, x] = fv[x] }
      k = ""; fld = ""; split("", fv)
    }
    FNR == 1 { flush(); sec = ""; inplan = FILENAME == ARGV[1] }
    /^## / { flush(); sec = $0; next }
    inplan && sec == "" && /^- \[[ x]\]/ { done[++boxes] = /^- \[x\]/; next }
    sec != "## Claims" { next }
    /^- Item [0-9]+ \((source|probe|drop)\): / {
      flush(); start = FNR; k = $0; it = $3 + 0; kd = $4; gsub(/[():]/, "", kd); next
    }
    k != "" && !inplan && match($0, /^  (Source|Call|Output|Environment|Test):/) {
      fld = substr($0, 3, RLENGTH - 3); v = substr($0, RLENGTH + 1); gsub(/[ \t]/, "", v)
      fv[fld] = v != ""; next
    }
    k != "" && fld != "" && /^   +[^ ]/ { fv[fld] = 1; next }
    k != "" && fld == "" && /^  +[^ ]/ { t = $0; sub(/^ +/, "", t); k = k " " t; next }
    { flush() }
    END {
      flush()
      need["source"] = need["drop"] = " Source "; need["probe"] = " Call Output Environment "
      n = split("Source Call Output Environment Test", fs, " ")
      for (c in line) {
        if (!(c in got)) {
          printf "PLAN-TEXT: %s:%d: claim without report entry\tentry\t%s\n", fp, line[c], c
          continue
        }
        if (!done[item[c]]) continue
        for (i = 1; i <= n; i++) {
          f = fs[i]
          if (((c, f) in val || index(need[kind[c]], " " f " ")) && !val[c, f])
            printf "PLAN-TEXT: %s:%d: claim of a done item with empty %s:\t%s\t%s\n", fr, got[c], f, f, c
        }
      }
    }' "$1" "$2"
}

added() {
  local out
  out=$(awk '
    { i = index($0, "\t"); k = substr($0, i + 1) }
    FILENAME == ARGV[1] { seen[k]++; next }
    seen[k] > 0 { seen[k]--; next }
    { print substr($0, 1, i - 1) }' "$old" "$new")
  [ -z "$out" ] || { printf '%s\n' "$out"; fail=1; }
}

judge() {
  local fn=$1 f=$2 from=$3; shift 3
  "$fn" "$f" "$f" "$@" > "$new"
  : > "$old"
  if [ -n "$from" ] && git show "$base:$from" > "$blob" 2>/dev/null; then "$fn" "$blob" "$f" "$@" > "$old"; fi
  added
}

pair() {
  local f=$1 from=$2
  [ -f "${f%.md}.report.md" ] || return 0
  claims "$f" "${f%.md}.report.md" "$f" > "$new"
  : > "$old"
  if [ -n "$from" ] && git show "$base:$from" > "$blob" 2>/dev/null \
    && git show "$base:${from%.md}.report.md" > "$blob2" 2>/dev/null; then
    claims "$blob" "$blob2" "$f" > "$old"
  fi
  added
}

had() { git cat-file -e "$base:$1" 2>/dev/null; }

while IFS=$'\t' read -r st f from; do
  [ -f "$f" ] || continue
  rel=${f#"$P"/}
  case $rel in archive/*) continue ;; ROADMAP.md) judge scan "$f" "$from" "" roadmap; continue ;; esac
  [[ $rel == *.findings.md ]] && { [[ $st == A ]] && echo "PLAN-TEXT: $f: findings file: use the task report" && fail=1; continue; }
  [[ $rel =~ ^R-?([0-9]{3})-[^/]*/([^/]+)$ ]] || continue
  id=R${BASH_REMATCH[1]}
  case ${BASH_REMATCH[2]} in
    requirements.md) judge scan "$f" "$from" "$id" req ;;
    tasks.md) judge scan "$f" "$from" "$id" tasks; judge backlog "$f" "$from" ;;
    *.report.md) if normal "${f%.report.md}.md"; then judge oneline "$f" "$from"; else judge report "$f" "$from"; fi
      pairs+="${f%.report.md}.md"$'\t'"${from%.report.md}"${from:+.md}$'\n' ;;
    *.md) judge scan "$f" "$from" "$id" plan
      normal "$f" && continue
      pairs+="$f"$'\t'"$from"$'\n'
      [ -f "${f%.md}.report.md" ] || [ -f "${f%.md}.findings.md" ] \
        || { [ -n "$from" ] && ! had "${from%.md}.report.md" && ! had "${from%.md}.findings.md"; } \
        || { echo "PLAN-TEXT: $f: plan without task report"; fail=1; }
      [[ $st == A ]] && for s in Claims Proven; do
        grep -qx "## $s" "$f" || { echo "PLAN-TEXT: $f: plan without ## $s"; fail=1; }
      done ;;
  esac
done < <(branch_changed "$base" "$P")

while IFS=$'\t' read -r f from; do
  [ -f "$f" ] && pair "$f" "$from"
done < <(printf '%s' "$pairs" | awk -F '\t' '
  !($1 in m) { o[++n] = $1 }
  !($1 in m) || m[$1] == "" { m[$1] = $2 }
  END { for (i = 1; i <= n; i++) print o[i] "\t" m[o[i]] }')

[ "$fail" -eq 0 ] && echo "check-plan-text: OK"
exit "$fail"
