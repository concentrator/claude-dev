#!/usr/bin/env bash
# rest-state-check.sh - the state check for a GitHub host whose CLI has REST
# only (skills/dev/companions/toolchain.md § State check). One `gh api` GET of
# the pull request, which fills {owner}/{repo} from the repository of the
# current directory, printing its state, merge time and head sha as one JSON
# object; a merged pull request reads `closed` with `merged_at` set.
# It takes the number alone, so the pre-flight's rule for the declared line -
# this script's path - reaches this one read and no other `gh api` call.
# Exit gh's status; 2 a usage error.
# Usage: rest-state-check.sh <pull request number>
set -uo pipefail

usage() { echo "usage: rest-state-check.sh <pull request number>" >&2; exit 2; }
[ $# -eq 1 ] || usage
case "$1" in '' | *[!0-9]*) usage ;; esac

exec gh api "repos/{owner}/{repo}/pulls/$1" --jq '{state, merged_at, head_sha: .head.sha}'
