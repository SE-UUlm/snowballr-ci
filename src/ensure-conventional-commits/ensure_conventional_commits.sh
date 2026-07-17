#!/usr/bin/env bash
set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $(basename "$0") [-r remote] [-t types] [branch]
Checks that all commits reachable from HEAD but not from <remote>/<branch> follow the
Conventional Commits specification (https://www.conventionalcommits.org/en/v1.0.0/).
Defaults: remote=origin, branch=develop, types=build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test

Options:
  -r remote   Remote name (default: origin)
  -t types    Comma-separated list of allowed commit types
  -h          Show this help
Examples:
  $(basename "$0")
  $(basename "$0") feature-branch
  $(basename "$0") -r origin -t "feat,fix" develop
EOF
}

# Default values
remote="origin"
branch="develop"
types="build,chore,ci,docs,feat,fix,perf,refactor,revert,style,test"

# Parse short options
while getopts ":r:t:h" opt; do
  case $opt in
  r) remote="$OPTARG" ;;
  t) types="$OPTARG" ;;
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

# Positional fallback: if a single positional arg is provided, treat it as branch
if [ $# -ge 1 ]; then
  branch="$1"
  # optionally accept a second positional arg as remote
  if [ $# -ge 2 ]; then
    remote="$2"
  fi
fi

# Build a regex matching "<type>[(scope)][!]: <description>" as per the
# Conventional Commits spec (https://www.conventionalcommits.org/en/v1.0.0/)
type_pattern=$(echo "$types" | tr ',' '|')
pattern="^(${type_pattern})(\([a-zA-Z0-9/_.-]+\))?!?: .+$"

# Merge commits are excluded: linear history is enforced separately, and merge
# commit subjects (e.g. "Merge pull request #...") are not meant to follow this spec.
commits=$(git rev-list --no-merges "${remote}/${branch}"..HEAD)
if [ -z "$commits" ]; then
  echo "No commits found since ${remote}/${branch}."
  exit 0
fi

invalid_found=0
for c in $commits; do
  subject=$(git log -1 --format=%s "$c")
  if ! [[ "$subject" =~ $pattern ]]; then
    echo "::error::Commit $c does not follow Conventional Commits: \"$subject\""
    invalid_found=1
  fi
done

if [ "$invalid_found" -eq 1 ]; then
  echo "One or more commits do not follow the Conventional Commits specification."
  echo "Allowed types: ${types}"
  echo "See https://www.conventionalcommits.org/en/v1.0.0/ for details."
  exit 1
fi

echo "All commits since ${remote}/${branch} follow the Conventional Commits specification."
