#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") -r owner/repo -n pr_number [-t token] [-o response.json] [-e env_file]
Fetch commits of a PR and output the SHA of the latest commit.

Options:
  -r repo       Repository in owner/repo form (default: \$GITHUB_REPOSITORY)
  -n pr_number  Pull request number
  -t token      GitHub token (default: \$GITHUB_TOKEN)
  -o file       Response JSON output file (default: response.json)
  -e env_file   Env output file to append LATEST_COMMIT_SHA (default: \$GITHUB_ENV if set)
  -h            Show this help
Example:
  ./retrieve_last_commit.sh -r myorg/myrepo -n 42 -t "\$GITHUB_TOKEN"
  # In GitHub Actions:
  ./retrieve_last_commit.sh -n 42 -t "\$GITHUB_TOKEN"
EOF
}

# Defaults from environment
repo="${GITHUB_REPOSITORY:-}"
pr_number=""
token="${GITHUB_TOKEN:-}"
response_file="response.json"
env_file="${GITHUB_ENV:-}"

# Parse options
while getopts ":r:n:t:o:e:h" opt; do
  case $opt in
  r) repo="$OPTARG" ;;
  n) pr_number="$OPTARG" ;;
  t) token="$OPTARG" ;;
  o) response_file="$OPTARG" ;;
  e) env_file="$OPTARG" ;;
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

if [ -z "$repo" ] || [ -z "$pr_number" ]; then
  echo "repo and pr_number are required." >&2
  usage
  exit 2
fi

api_url="https://api.github.com/repos/${repo}/pulls/${pr_number}/commits"

# Build curl headers
headers=(-H "Accept: application/vnd.github.v3+json" -H "Content-Type: application/json")
if [ -n "${token:-}" ]; then
  headers+=(-H "Authorization: token ${token}")
fi

# Fetch commits (fail on HTTP errors)
if ! response=$(curl -sS -f "${headers[@]}" "$api_url"); then
  echo "::error::Failed to fetch commits from ${api_url}" >&2
  exit 3
fi

# Save response
printf '%s\n' "$response" >"$response_file"

# Ensure we have at least one commit and extract last commit SHA
length=$(jq 'length' "$response_file")
if [ "$length" -eq 0 ]; then
  echo "::error::No commits found for PR ${pr_number} in ${repo}" >&2
  exit 4
fi

index=$((length - 1))
latest_commit_sha=$(jq -r --argjson idx "$index" '.[$idx].sha' "$response_file")

echo "Latest Commit SHA: $latest_commit_sha"

# Append to env file if provided (useful in GitHub Actions)
if [ -n "${env_file:-}" ]; then
  printf 'LATEST_COMMIT_SHA=%s\n' "$latest_commit_sha" >>"$env_file"
fi

# Also print on stdout for scripts that capture it
printf '%s\n' "$latest_commit_sha"
