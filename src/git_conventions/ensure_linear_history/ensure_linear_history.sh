#!/usr/bin/env bash
set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $(basename "$0") [-r remote] [-b branch] [branch]
Checks that <remote>/<branch> is not merged into the history of the current HEAD.
Defaults: remote=origin, branch=develop

Options:
  -r remote   Remote name (default: origin)
  -b branch   Branch name on remote (default: develop)
  -h          Show this help
Examples:
  $(basename "$0")
  $(basename "$0") feature-branch
  $(basename "$0") -r origin -b develop
EOF
}

# Default values
remote="origin"
branch="develop"

# Parse short options
while getopts ":r:b:h" opt; do
  case $opt in
  r) remote="$OPTARG" ;;
  b) branch="$OPTARG" ;;
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

# Find merge commits reachable from HEAD but not from <remote>/<branch>
merges=$(git rev-list --merges $remote/$branch..HEAD)
if [ -z "$merges" ]; then
  echo "No merge commits found in the current branch since $remote/$branch."
  exit 0
fi

for m in $merges; do
  # get all parents of the merge commit
  parents=$(git rev-list --parents -n 1 "$m" | cut -d' ' -f2-)
  for p in $parents; do
    if git merge-base --is-ancestor "$remote/$branch" "$p"; then
      echo "::error ::Found merge commit $m that merged $branch into the current branch (parent $p contains $remote/$branch)."
      echo "=== Merge commit details ==="
      git --no-pager show --pretty=fuller --name-only "$m"
      echo "=== Nearby commits (graph) ==="
      git --no-pager log --oneline --graph --decorate --boundary "$m"~5.."$m" || true
      exit 1
    fi
  done
done

echo "No merges from $remote/$branch found in the current branch."
