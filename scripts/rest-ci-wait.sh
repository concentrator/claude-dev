#!/usr/bin/env bash
# rest-ci-wait.sh - the CI wait for a GitHub host whose CLI has REST only
# (skills/dev/companions/toolchain.md § CI wait). Reads the pull request's head
# sha once, then polls that sha's check runs until every run completes, making
# only GET requests through `gh api`, which fills {owner}/{repo} from the
# repository of the current directory.
# Prints one line per check run - name, pass or fail, job URL - then an outcome
# line naming the head sha. A run passes when its conclusion is `success`.
# Exit 0 every check passed; 1 a check failed, or no check registered within
# EMPTY_POLLS polls, printing `no checks reported`; 2 a usage or host error.
# REST_CI_WAIT_INTERVAL sets the seconds between polls (default 10).
# Usage: rest-ci-wait.sh <pull request number>
set -uo pipefail

INTERVAL=${REST_CI_WAIT_INTERVAL:-10}
EMPTY_POLLS=6

n=${1:-}
case "$n" in
  '' | *[!0-9]*) echo "usage: rest-ci-wait.sh <pull request number>" >&2; exit 2 ;;
esac

sha=$(gh api "repos/{owner}/{repo}/pulls/$n" --jq .head.sha) && [ -n "$sha" ] \
  || { echo "rest-ci-wait: no head sha for pull request $n" >&2; exit 2; }

empty=0
while :; do
  runs=$(gh api "repos/{owner}/{repo}/commits/$sha/check-runs?per_page=100" \
    --jq '.check_runs[] | [.name, .status, (.conclusion // ""), .html_url] | @tsv') \
    || { echo "rest-ci-wait: the check runs of $sha did not read" >&2; exit 2; }
  if [ -z "$runs" ]; then
    empty=$((empty + 1))
    [ "$empty" -lt "$EMPTY_POLLS" ] || { echo "no checks reported on $sha"; exit 1; }
  elif printf '%s\n' "$runs" | awk -F '\t' '$2 != "completed" { open = 1 } END { exit open }'; then
    break
  fi
  sleep "$INTERVAL"
done

printf '%s\n' "$runs" | awk -F '\t' -v OFS='\t' '{ print $1, ($3 == "success" ? "pass" : "fail"), $4 }'
total=$(printf '%s\n' "$runs" | wc -l | tr -d ' ')
failed=$(printf '%s\n' "$runs" | awk -F '\t' '$3 != "success"' | wc -l | tr -d ' ')
if [ "$failed" -eq 0 ]; then
  echo "$sha: all $total checks passed"
  exit 0
fi
echo "$sha: $failed of $total checks failed"
exit 1
