#!/usr/bin/env bash
set -euo pipefail

# Usage function
usage() {
  cat <<EOF
Usage: $(basename "$0") [-r remote] [-b branch] [branch]
Checks that the current HEAD contains the history of <remote>/<branch>.
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

# Fail if <remote>/<branch> is not an ancestor of the current HEAD
if git merge-base --is-ancestor "${remote}/${branch}" HEAD; then
  echo "Current branch has the same history as ${remote}/${branch}"
else
  echo "::error ::Current branch has not the same history as ${remote}/${branch}. Please rebase onto ${branch}."
  echo "=== Commit difference (${remote}/${branch}...HEAD) ==="
  git --no-pager log --oneline --decorate --graph --boundary --left-right "${remote}/${branch}...HEAD" || true
  exit 1
fi
