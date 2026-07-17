#!/usr/bin/env bash
set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $(basename "$0") [-t types] [-i ignore-patterns] <branch-name>
Checks that <branch-name> has the form <type>/<issue-number>-<slug>, where <type> is one of
the allowed Conventional Commits types (https://www.conventionalcommits.org/en/v1.0.0/).
Example: feat/1-add-login-page
Defaults: types=build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test

Options:
  -t types             Comma-separated list of allowed branch type prefixes
  -i ignore-patterns   Comma-separated list of glob patterns; branches matching any of them are skipped
  -h                   Show this help
Examples:
  $(basename "$0") feat/1-add-login-page
  $(basename "$0") -t "feat,fix" -i "releases/*,dependabot/*" chore/2-bump-deps
EOF
}

# Default values
types="build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test"
ignore_patterns=""

# Parse short options
while getopts ":t:i:h" opt; do
  case $opt in
  t) types="$OPTARG" ;;
  i) ignore_patterns="$OPTARG" ;;
  h)
    usage
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    exit 2
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    exit 2
    ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
  echo "Missing required <branch-name> argument." >&2
  usage
  exit 2
fi
branch="$1"

# Skip branches matching any ignore pattern (glob syntax, e.g. "releases/*")
if [ -n "$ignore_patterns" ]; then
  IFS=',' read -ra patterns <<<"$ignore_patterns"
  for pattern in "${patterns[@]}"; do
    if [[ "$branch" == $pattern ]]; then
      echo "Branch '$branch' matches ignore pattern '$pattern'; skipping check."
      exit 0
    fi
  done
fi

# Build a regex matching "<type>/<issue-number>-<slug>", e.g. "feat/1-add-login-page"
type_pattern=$(echo "$types" | tr ',' '|')
pattern="^(${type_pattern})/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$"

if [[ "$branch" =~ $pattern ]]; then
  echo "Branch '$branch' follows the expected naming convention."
else
  echo "::error::Branch '$branch' does not follow the expected naming convention '<type>/<issue-number>-<slug>' (e.g. feat/1-add-login-page)."
  echo "Allowed types: ${types}"
  exit 1
fi
