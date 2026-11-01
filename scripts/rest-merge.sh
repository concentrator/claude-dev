#!/usr/bin/env bash
# rest-merge.sh - the merge for a GitHub host whose CLI has REST only
# (skills/dev/companions/toolchain.md § Merge). One `gh api` PUT, which fills
# {owner}/{repo} from the repository of the current directory, merging the pull
# request with a merge commit while its head is the sha given - the head sha
# the CI wait passed. The fields go as -f, so the sha is sent as a string. A
# head moved past that sha answers HTTP 409 "Head branch was modified", leaves
# the pull request open, and gh exits non-zero; a merge prints the merge
# commit's sha. A pull request already merged answers with its merge again,
# exit 0, so the state check stays the read of merged state.
# It takes the number and a full sha alone, so the pre-flight's rule for the
# declared line - this script's path - reaches this one merge and no other
# `gh api` call.
# Exit gh's status; 2 a usage error.
# Usage: rest-merge.sh <pull request number> <head sha>
set -uo pipefail

usage() { echo "usage: rest-merge.sh <pull request number> <head sha>" >&2; exit 2; }
[ $# -eq 2 ] || usage
case "$1" in '' | *[!0-9]*) usage ;; esac
case "$2" in *[!0-9a-f]*) usage ;; esac
[ "${#2}" -eq 40 ] || usage

exec gh api -X PUT "repos/{owner}/{repo}/pulls/$1/merge" -f merge_method=merge -f "sha=$2"
