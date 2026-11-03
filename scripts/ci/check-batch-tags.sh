#!/usr/bin/env bash
set -uo pipefail
top="$(git rev-parse --show-toplevel)" \
  || { echo "BATCH-TAGS: not inside a git repo"; exit 1; }
cd "$top"

P=$(sed -n 's/^- Plans: *//p' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1 || true)
P=${P:-dev/plans}
P=${P%/}

# The anchor tag is never pushed and the batch branch reaches origin
# only at accept (branch-plan.md § Rails), so a CI runner or shallow clone sees at
# most a slice of the refs - report the blindness rather than a hollow
# OK. CI must be truthy: a workstation exporting CI=false still
# enforces.
case "${CI:-}" in
  ''|0|false) ;;
  *) echo "check-batch-tags: SKIP (batch refs not visible)"; exit 0 ;;
esac
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "check-batch-tags: SKIP (batch refs not visible)"
  exit 0
fi

# The trunk: origin's default branch, else local main, else HEAD (a
# remote-less repo is its own trunk).
if trunk="$(git symbolic-ref -q --short refs/remotes/origin/HEAD)"; then :
elif git show-ref -q --verify refs/heads/main; then trunk=main
else trunk=HEAD; fi
tree="$(git ls-tree -r --name-only "$trunk" -- "$P" 2>/dev/null || true)"

fail=0
report() { echo "BATCH-TAGS: $1"; fail=1; }

# Judge one batch-namespace ref: $1 = the ref as shown, $2 = its
# composite remainder, $3 = the expected full form, $4 = extra remedy
# appended to the stale verdict. Ids are matched by digits, so a ref
# in either spelling resolves against a dir and report in either. The
# ls-tree listing is already scoped to the declared plans tree, so the
# patterns carry no prefix (and need no escaping).
judge() {
  local ref="$1" rest="$2" want="$3" hint="${4:-}" nnn mmm rep
  if [[ "$rest" =~ ^R([0-9]{3})-B-?([0-9]{3})$ ]]; then
    nnn="${BASH_REMATCH[1]}"; mmm="${BASH_REMATCH[2]}"
    rep="$(grep -E -m1 "(^|/)R-?$nnn-[^/]+/batches/(B-$mmm|R$nnn-B$mmm)\.report\.md$" <<<"$tree" || true)"
    if [ -n "$rep" ]; then
      report "$ref outlived its batch - $trunk carries $rep; batch.md § Refs retires the ref$hint"
    elif ! grep -qE "(^|/)R-?$nnn-" <<<"$tree"; then
      report "$ref names no initiative R$nnn on $trunk - unresolvable"
    fi
  else
    report "$ref is not a composite batch ref ($want; legacy ${want/B<NNN>/B-XXX}) - unresolvable"
  fi
}

# One enumeration over all refs; the case patterns route the two batch
# namespaces (and cross slashes, so nested batch/ refs cannot escape).
while IFS= read -r full; do
  case "$full" in
    refs/tags/pre-*)
      judge "${full#refs/tags/}" "${full#refs/tags/pre-}" 'pre-R<NNN>-B<NNN>' ;;
    refs/heads/batch/*)
      judge "${full#refs/heads/}" "${full##*batch/}" 'batch/R<NNN>-B<NNN>' ;;
    refs/remotes/*/batch/*)
      judge "${full#refs/remotes/}" "${full##*batch/}" 'batch/R<NNN>-B<NNN>' \
            '; already gone from origin? git fetch --prune' ;;
  esac
done < <(git for-each-ref --format='%(refname)')

(( fail == 0 )) && echo "check-batch-tags: OK"
exit $fail
