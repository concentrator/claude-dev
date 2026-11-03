#!/usr/bin/env bash
# Tests scripts/ci/check-plan-text.sh in throwaway git repos.
# Run: bash scripts/test/check-plan-text.test.sh
set -uo pipefail
# Never inherit a git environment - see scripts/test/isolation.test.sh.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../ci" && pwd)/check-plan-text.sh"
[ -f "$CHECK" ] || { echo "not ok - $CHECK not found"; exit 1; }
OWN=R100
fail=0
pass() { echo "ok - $1"; }
die()  { echo "not ok - $1"; fail=1; }
commit_in() { git -C "$1" add -A; git -C "$1" -c user.email=t@t -c user.name=t commit -qm "$2"; }

mkrepo() { # main holds a roadmap and a legacy initiative; the branch adds $OWN-x
  local d; d=$(mktemp -d); git -C "$d" init -q -b "${1:-main}"
  mkdir -p "$d/dev/plans/R090-old"
  printf '# Roadmap\n\n- [ ] %s: Title - what it delivers.\n' "$OWN" > "$d/dev/plans/ROADMAP.md"
  printf 'See https://example.com on 2026-01-01, #12, R001.\n' > "$d/dev/plans/R090-old/requirements.md"
  commit_in "$d" init
  git -C "$d" checkout -q -b feat
  mkdir -p "$d/dev/plans/$OWN-x"
  printf '# %s: Title\n\n## Goal\n\nA goal.\n' "$OWN" > "$d/dev/plans/$OWN-x/requirements.md"
  printf '# %s tasks\n\n- [ ] **%s-T001 [mnt]**: do a thing.\n' "$OWN" "$OWN" > "$d/dev/plans/$OWN-x/tasks.md"
  printf '%s' "$d"
}
run_in() { ( cd "$1" && git add -A && bash "$CHECK" 2>&1 ); }

d=$(mkrepo)
out=$(run_in "$d") && pass "clean changes pass, unchanged legacy text skipped" || die "clean failed: $out"
rm -rf "$d"

expect() { # description, file under dev/plans, content, expected reason
  local d out; d=$(mkrepo)
  mkdir -p "$(dirname "$d/dev/plans/$2")"
  printf '%s\n' "$3" >> "$d/dev/plans/$2"
  out=$(run_in "$d")
  case "$out" in *"$4"*) pass "$1" ;; *) die "$1: $out" ;; esac
  rm -rf "$d"
}
expect "URL caught"            "$OWN-x/requirements.md" "Spec: https://example.com" "link"
expect "markdown link caught"  "$OWN-x/tasks.md"        "See [doc](docs/x.md)"      "link"
expect "date caught"           "$OWN-x/tasks.md"        "Probed 2026-09-17."        "date"
expect "PR ref caught"         "$OWN-x/requirements.md" "Shipped in #545."          "#NNN ref"
expect "commit hash caught"    "$OWN-x/tasks.md"        "Fixed by b0182f8."         "commit hash"
expect "foreign id caught"     "$OWN-x/requirements.md" "Builds on R000-T002."      "id of another initiative: R000"
accept() { # description, file under dev/plans, content: the check passes
  local d out; d=$(mkrepo)
  printf '%s\n' "$3" >> "$d/dev/plans/$2"
  out=$(run_in "$d") && pass "$1" || die "$1: $out"
  rm -rf "$d"
}
accept "foreign id in tasks.md passes" "$OWN-x/tasks.md" "  Builds on R000-T002 and R-083."
accept "foreign id in ROADMAP passes"  "ROADMAP.md"      "  Builds on R000-T002 and R-083."
expect "long task entry caught" "$OWN-x/tasks.md" "$(printf -- '- [ ] **%s-T002 [mnt]**: a\n  b\n  c\n  d' "$OWN")" "entry over 3 lines"
expect "wrapped backlog paragraph caught" "$OWN-x/tasks.md" "$(printf '\nBacklog: a note\nwrapped onto a second line.')" "tasks.md:5: backlog line over 1 line"
expect "wrapped backlog bullet caught" "$OWN-x/tasks.md" "$(printf '\n- a backlog note\n  wrapped under its bullet.')" "tasks.md:5: backlog line over 1 line"
d=$(mkrepo)
printf '# %s tasks\n\nWhy: a reason that\nwraps.\n\n## Open\n\n- [ ] **%s-T001 [mnt]**: a\n  b.\n\n- one backlog note.\n- another one.\n\nBacklog: a line.\n' "$OWN" "$OWN" > "$d/dev/plans/$OWN-x/tasks.md"
out=$(run_in "$d") && pass "one-line backlog lines pass" || die "one-line backlog lines failed: $out"
rm -rf "$d"
d=$(mkrepo)
printf 'More.\n' >> "$d/dev/plans/R090-old/requirements.md"
out=$(run_in "$d") && pass "old text in a changed legacy file passes" || die "changed legacy file failed: $out"
rm -rf "$d"
expect "added line in a legacy file caught" "R090-old/requirements.md" "See https://example.com." "PLAN-TEXT: dev/plans/R090-old/requirements.md:2: link"
expect "added copy of an old line caught" "R090-old/requirements.md" "See https://example.com on 2026-01-01, #12, R001." "PLAN-TEXT: dev/plans/R090-old/requirements.md:2: link"
on_main() { # repo file content: main gains the file, the branch then merges
  git -C "$1" checkout -q main
  printf '%s\n' "$3" > "$1/dev/plans/$2"
  commit_in "$1" "$2"
  git -C "$1" checkout -q feat
  git -C "$1" -c user.email=t@t -c user.name=t merge -q --no-edit main
}
d=$(mkrepo); on_main "$d" R090-old/tasks.md "$(printf -- '- [ ] **R090-T001 [mnt]**: a\n  b\n  c\n  d')"
printf -- '- [x] **R090-T001 [mnt]**: a\n  b\n  c\n  d\n  e\n' > "$d/dev/plans/R090-old/tasks.md"
out=$(run_in "$d") && pass "old long entry checked off and grown passes" || die "old long entry failed: $out"
printf -- '- [ ] **R090-T002 [mnt]**: a\n  b\n  c\n  d\n' >> "$d/dev/plans/R090-old/tasks.md"
out=$(run_in "$d"); case "$out" in *"tasks.md:6: entry over 3 lines"*) pass "new long entry beside an old one caught" ;; *) die "new long entry: $out" ;; esac
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.report.md "$(printf -- '- [ ] shape may differ\n  no evidence')"
printf -- '- [x] shape may differ\n  no evidence\n- [ ] another\n' > "$d/dev/plans/R090-old/R090-T001-old.report.md"
out=$(run_in "$d"); case "$out" in *"report.md:3: finding without Evidence"*) [[ $out != *"report.md:1:"* ]] && pass "old box passes, new box without evidence caught" || die "old box reported: $out" ;; *) die "new box: $out" ;; esac
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "- [ ] an item"
printf -- '- [x] an item\n' > "$d/dev/plans/R090-old/R090-T001-old.md"
out=$(run_in "$d") && pass "legacy plan without a report passes" || die "legacy plan without a report failed: $out"
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "- [ ] an item"; on_main "$d" R090-old/R090-T001-old.report.md "# report"
git -C "$d" rm -q dev/plans/R090-old/R090-T001-old.report.md
printf -- '- [x] an item\n' > "$d/dev/plans/R090-old/R090-T001-old.md"
out=$(run_in "$d"); case "$out" in *"R090-T001-old.md: plan without task report"*) pass "plan losing its report caught" ;; *) die "plan losing its report: $out" ;; esac
rm -rf "$d"
expect "R-NNN dir checked"     "R-083-y/requirements.md" "Builds on R000-T002."     "id of another initiative: R000"

d=$(mkrepo)
mkdir -p "$d/dev/plans/R-083-y"
printf 'Own id R-083-T001.\n' > "$d/dev/plans/R-083-y/requirements.md"
out=$(run_in "$d") && pass "R-NNN dir's own id passes" || die "R-NNN own id failed: $out"
rm -rf "$d"

d=$(mkrepo)
mkdir -p "$d/dev/plans/archive/R050-z"
printf 'See https://example.com.\n' > "$d/dev/plans/archive/R050-z/requirements.md"
printf -- '- [ ] **R050-T001**: https://example.com\n' > "$d/dev/plans/archive/ROADMAP.md"
out=$(run_in "$d") && pass "archive excluded" || die "archive checked: $out"
rm -rf "$d"

d=$(mkrepo)
printf 'Spec: https://example.com\n' >> "$d/dev/plans/$OWN-x/requirements.md"
commit_in "$d" branch-work
out=$(run_in "$d"); case "$out" in *"link"*) pass "committed branch change caught" ;; *) die "committed change: $out" ;; esac
rm -rf "$d"

d=$(mkrepo trunk)
printf 'Spec: https://example.com\n' >> "$d/dev/plans/$OWN-x/requirements.md"
out=$(run_in "$d"); rc=$?
[ $rc -eq 0 ] && grep -q 'check-plan-text: SKIP (no default branch)' <<<"$out" \
  && pass "no default branch skips by name" || die "no default branch (rc=$rc): $out"
rm -rf "$d"

expect "finding without evidence caught" "$OWN-x/$OWN-T001-x.report.md" "$(printf -- '- [ ] shape may differ\n  Evidence: hypothetical reading of code')" "finding without Evidence"
d=$(mkrepo)
printf -- '- [ ] 400 on empty body\n  Evidence: observed curl response in the probe\n' > "$d/dev/plans/$OWN-x/$OWN-T001-x.report.md"
out=$(run_in "$d") && pass "finding with evidence passes" || die "finding with evidence failed: $out"
rm -rf "$d"

expect "added findings file caught" "$OWN-x/$OWN-T001-x.findings.md" "- a note" "PLAN-TEXT: dev/plans/$OWN-x/$OWN-T001-x.findings.md: findings file: use the task report"
item() { printf -- '- [ ] an item\n'; for i in $(seq 2 "$1"); do printf '  line %s\n' "$i"; done; }
none() { printf '\n## Claims\n- none\n\n## Proven\n- none\n'; }
with_findings() { # repo: main gains a findings file with a 7-line item, the branch then merges
  git -C "$1" checkout -q main
  item 7 > "$1/dev/plans/R090-old/R090-T001-old.findings.md"
  commit_in "$1" findings
  git -C "$1" checkout -q feat
  git -C "$1" -c user.email=t@t -c user.name=t merge -q --no-edit main
}
d=$(mkrepo); with_findings "$d"
printf -- '- another finding\n' >> "$d/dev/plans/R090-old/R090-T001-old.findings.md"
out=$(run_in "$d") && pass "existing findings file passes" || die "existing findings file failed: $out"
rm -rf "$d"
d=$(mkrepo); with_findings "$d"
git -C "$d" mv dev/plans/R090-old/R090-T001-old.findings.md dev/plans/R090-old/R090-T001-kept.findings.md
out=$(run_in "$d") && pass "renamed findings file passes" || die "renamed findings file failed: $out"
rm -rf "$d"

d=$(mkrepo)
{ item 6; none; } > "$d/dev/plans/$OWN-x/$OWN-T001-x.md"
printf '# %s-T001 report\n' "$OWN" > "$d/dev/plans/$OWN-x/$OWN-T001-x.report.md"
out=$(run_in "$d") && pass "6-line plan item with its report passes" || die "6-line plan item failed: $out"
rm -rf "$d"
d=$(mkrepo); with_findings "$d"
{ printf -- '- [ ] an item\n'; none; } > "$d/dev/plans/R090-old/R090-T001-old.md"
out=$(run_in "$d") && pass "plan with its legacy findings file passes" || die "plan with legacy findings file failed: $out"
rm -rf "$d"
expect "plan without task report caught" "$OWN-x/$OWN-T001-x.md" "- [ ] an item" "PLAN-TEXT: dev/plans/$OWN-x/$OWN-T001-x.md: plan without task report"
d=$(mkrepo)
printf -- '- [ ] an item\n' > "$d/dev/plans/$OWN-x/$OWN-T001-x.md"
printf '# %s-T002 report\n' "$OWN" > "$d/dev/plans/$OWN-x/$OWN-T002-y.report.md"
out=$(run_in "$d"); case "$out" in *"$OWN-T001-x.md: plan without task report"*) pass "another plan's report does not count" ;; *) die "another plan's report: $out" ;; esac
rm -rf "$d"
expect "7-line plan item caught" "$OWN-x/$OWN-T001-x.md" "$(item 7)" "PLAN-TEXT: dev/plans/$OWN-x/$OWN-T001-x.md:1: item over 6 lines"
d=$(mkrepo)
mkdir -p "$d/dev/plans/$OWN-x/batches"
item 7 > "$d/dev/plans/$OWN-x/batches/B001.md"
out=$(run_in "$d") && pass "batches excluded from the plan check" || die "batches checked: $out"
rm -rf "$d"

d=$(mkrepo)
printf -- '- [ ] an item\n' > "$d/dev/plans/$OWN-x/$OWN-T001-x.md"
printf '# %s-T001 report\n' "$OWN" > "$d/dev/plans/$OWN-x/$OWN-T001-x.report.md"
out=$(run_in "$d")
[[ $out == *"$OWN-T001-x.md: plan without ## Claims"* && $out == *"$OWN-T001-x.md: plan without ## Proven"* ]] \
  && pass "added plan without claims and proven caught" || die "added plan without sections: $out"
rm -rf "$d"
claim_a='- Item 1 (source): `check-x` exits 1 on a missing file.'
claim_b=$(printf -- '- Item 1 (probe): A page holds at most 100 rows,\n  even when `limit` asks for more.')
entry_a=$(printf '%s\n  Source:' "$claim_a")
entry_b=$(printf '%s\n  Call: curl -s %s\n  Output:\n    {"rows": [], "next": "c2"}\n  Test: scripts/test/rows.test.sh\n  Environment:' "$claim_b" "'https://api.test/rows?limit=500'")
plan_of() { printf -- '%s\n\n## Claims\n%s\n\n## Proven\n- none\n' "${2:-- [ ] an item}" "$1"; }
report_of() { printf '# report\n\n## Claims\n%s\n\n## Implementer\n' "$1"; }
claims_in() { plan_of "$3" "${5:-}" > "$1/dev/plans/$2.md"; report_of "$4" > "$1/dev/plans/$2.report.md"; }
both="$claim_a"$'\n'"$claim_b"
lacking="PLAN-TEXT: dev/plans/R090-old/R090-T001-old.md:5: claim without report entry"
d=$(mkrepo); claims_in "$d" "$OWN-x/$OWN-T001-x" "$both" "$entry_a"$'\n'"$entry_b"
out=$(run_in "$d") && pass "claims with their report entries pass" || die "claims with entries failed: $out"
claims_in "$d" "$OWN-x/$OWN-T001-x" "$both" "$entry_a"
out=$(run_in "$d")
[[ $out == *"PLAN-TEXT: dev/plans/$OWN-x/$OWN-T001-x.md:5: claim without report entry"* ]] \
  && [ "$(grep -c '^PLAN-TEXT' <<<"$out")" -eq 1 ] \
  && pass "claim without report entry caught once" || die "claim without entry: $out"
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "$(plan_of "$both")"
on_main "$d" R090-old/R090-T001-old.report.md "$(report_of "$entry_a")"
printf '\n## Review\n' >> "$d/dev/plans/R090-old/R090-T001-old.report.md"
out=$(run_in "$d") && pass "claim lacking its entry at the base passes" || die "base violation reported: $out"
git -C "$d" reset -q --hard
git -C "$d" mv dev/plans/R090-old/R090-T001-old.md dev/plans/R090-old/R090-T001-kept.md
git -C "$d" mv dev/plans/R090-old/R090-T001-old.report.md dev/plans/R090-old/R090-T001-kept.report.md
out=$(run_in "$d") && pass "renamed plan and report pass" || die "renamed pair failed: $out"
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "$(plan_of "$both")"
on_main "$d" R090-old/R090-T001-old.report.md "$(report_of "$entry_a"$'\n'"$entry_b")"
report_of "$entry_a" > "$d/dev/plans/R090-old/R090-T001-old.report.md"
out=$(run_in "$d"); case "$out" in *"$lacking"*) pass "report entry removed on the branch caught" ;; *) die "removed entry: $out" ;; esac
rm -rf "$d"

claim_c='- Item 2 (drop): the `--legacy` flag.'
filled_a=$(printf '%s\n  Source: scripts/check-x.sh main' "$claim_a")
probe_of() { printf '%s\n  Call: curl -s %s\n%s' "$claim_b" "'https://api.test/rows?limit=500'" "$1"; }
filled_b=$(probe_of $'  Output:\n    {"rows": [], "next": "c2"}\n  Test: scripts/test/rows.test.sh\n  Environment: a test client')
entry_c=$(printf '%s\n  Source:' "$claim_c")
three="$both"$'\n'"$claim_c"
first=$'- [x] one\n- [ ] two'
rep="PLAN-TEXT: dev/plans/$OWN-x/$OWN-T001-x.report.md"
empty="claim of a done item with empty"
gap() { # description, Item 1's probe entry, expected line
  local d out; d=$(mkrepo)
  claims_in "$d" "$OWN-x/$OWN-T001-x" "$three" "$filled_a"$'\n'"$2"$'\n'"$entry_c" "$first"
  out=$(run_in "$d")
  [[ $out == *"$3"* ]] && [ "$(grep -c '^PLAN-TEXT' <<<"$out")" -eq 1 ] && pass "$1" || die "$1: $out"
  rm -rf "$d"
}
d=$(mkrepo); claims_in "$d" "$OWN-x/$OWN-T001-x" "$three" "$filled_a"$'\n'"$filled_b"$'\n'"$entry_c" "$first"
out=$(run_in "$d") && pass "done item's filled entries pass beside an open item's blank one" || die "filled entries failed: $out"
claims_in "$d" "$OWN-x/$OWN-T001-x" "$three" "$entry_a"$'\n'"$filled_b"$'\n'"$entry_c" "$first"
out=$(run_in "$d")
[[ $out == *"$rep:4: $empty Source:"* ]] && [ "$(grep -c '^PLAN-TEXT' <<<"$out")" -eq 1 ] \
  && pass "done item's blank source entry caught" || die "blank source entry: $out"
claims_in "$d" "$OWN-x/$OWN-T001-x" "$three" "$filled_a"$'\n'"$filled_b"$'\n'"$entry_c" $'- [x] one\n- [x] two'
out=$(run_in "$d"); case "$out" in *"$rep:13: $empty Source:"*) pass "done item's blank drop entry caught" ;; *) die "blank drop entry: $out" ;; esac
rm -rf "$d"
gap "done item's probe entry with an empty Output caught" "$(probe_of $'  Output:\n  Test: t\n  Environment: e')" "$rep:6: $empty Output:"
gap "done item's probe entry without Environment caught" "$(probe_of $'  Output:\n    o')" "$rep:6: $empty Environment:"
gap "done item's entry with an empty Test caught" "$(probe_of $'  Output: o\n  Environment: e\n  Test:')" "$rep:6: $empty Test:"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "$(plan_of "$claim_a")"
on_main "$d" R090-old/R090-T001-old.report.md "$(report_of "$entry_a")"
plan_of "$claim_a" "- [x] an item" > "$d/dev/plans/R090-old/R090-T001-old.md"
out=$(run_in "$d"); case "$out" in *"R090-T001-old.report.md:4: $empty Source:"*) pass "item marked done over a blank entry caught" ;; *) die "marked done: $out" ;; esac
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/R090-T001-old.md "$(plan_of "$claim_a" "- [x] an item")"
on_main "$d" R090-old/R090-T001-old.report.md "$(report_of "$filled_a")"
report_of "$entry_a" > "$d/dev/plans/R090-old/R090-T001-old.report.md"
out=$(run_in "$d"); case "$out" in *"R090-T001-old.report.md:4: $empty Source:"*) pass "done entry emptied on the branch caught" ;; *) die "emptied entry: $out" ;; esac
git -C "$d" add -A; git -C "$d" -c user.email=t@t -c user.name=t commit -qm empty
git -C "$d" checkout -q main; git -C "$d" merge -q feat; git -C "$d" checkout -q -b next
printf '\n## Review\n' >> "$d/dev/plans/R090-old/R090-T001-old.report.md"
out=$(run_in "$d") && pass "done item's blank entry at the base passes" || die "base blank entry reported: $out"
rm -rf "$d"

d=$(mkrepo)
for i in $(seq 1 40); do echo "line $i"; done >> "$d/dev/plans/$OWN-x/requirements.md"
out=$(run_in "$d"); case "$out" in *"over 40 lines"*) pass "long requirements caught" ;; *) die "long requirements: $out" ;; esac
rm -rf "$d"

d=$(mkrepo)
printf -- '- [ ] a\n  * [x] b\n+ [ ] c\n1. [x] d\n\t12) [ ] e\n' >> "$d/dev/plans/$OWN-x/requirements.md"
out=$(run_in "$d")
[ "$(grep -c 'requirements.md:[0-9]*: checkbox' <<<"$out")" -eq 5 ] \
  && pass "checkbox after any list marker in a new requirements.md caught" || die "new file's boxes: $out"
printf '# %s: Title\n\n1. An outcome.\n2. See [x] or - [ ] mid-line.\n[ ] no marker.\n' "$OWN" > "$d/dev/plans/$OWN-x/requirements.md"
out=$(run_in "$d") && pass "numbered outcomes and boxes off a list marker pass" || die "outcomes without boxes: $out"
rm -rf "$d"
d=$(mkrepo); on_main "$d" R090-old/requirements.md "$(printf -- '- [ ] an outcome\n  1. [ ] a nested one')"
printf -- '- [x] an outcome\n  1. [x] a nested one\n' > "$d/dev/plans/R090-old/requirements.md"
out=$(run_in "$d") && pass "older boxes checked off pass" || die "older boxes checked off: $out"
printf -- '- [ ] another outcome\n' >> "$d/dev/plans/R090-old/requirements.md"
out=$(run_in "$d")
[[ $out == *"PLAN-TEXT: dev/plans/R090-old/requirements.md:3: checkbox"* ]] && [ "$(grep -c '^PLAN-TEXT' <<<"$out")" -eq 1 ] \
  && pass "box added to an older requirements.md caught" || die "added box: $out"
rm -rf "$d"

d=$(mkrepo)
printf '      one\n      two\n      three\n' >> "$d/dev/plans/ROADMAP.md"
out=$(run_in "$d"); case "$out" in *"entry over 3 lines"*) pass "long roadmap entry caught" ;; *) die "long roadmap entry: $out" ;; esac
rm -rf "$d"

normal_plan() { printf -- '---\ntask: %s-T001\nmode: normal\n---\n\n- [x] an item\n' "$OWN" > "$1/dev/plans/$OWN-x/$OWN-T001-x.md"; }
d=$(mkrepo); normal_plan "$d"
out=$(run_in "$d") && pass "normal plan without report, claims or proven passes" || die "normal plan: $out"
printf -- '# report\n\n## Review\n- [ ] Item 1: a finding - a.sh:3\n' > "$d/dev/plans/$OWN-x/$OWN-T001-x.report.md"
out=$(run_in "$d") && pass "normal report box without evidence passes" || die "normal report box: $out"
printf -- '- [ ] Item 1: a finding\n  wrapped onto a second line\n' >> "$d/dev/plans/$OWN-x/$OWN-T001-x.report.md"
out=$(run_in "$d"); case "$out" in *"report.md:5: report entry over 1 line"*) pass "normal report entry over one line caught" ;; *) die "normal wrapped entry: $out" ;; esac
rm -rf "$d"

[ "$fail" -eq 0 ] && echo "check-plan-text.test: OK"
exit "$fail"
