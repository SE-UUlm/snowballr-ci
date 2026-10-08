#!/usr/bin/env bash
# Checks links matching the given glob patterns and only emits GitHub warnings for unreachable ones instead of failing.
# Usage: check-warn-links.sh <comma-separated-link-patterns> <comma-separated-ignore-paths>

set -uo pipefail

IFS=',' read -ra PATTERNS <<< "${1:-}"
IFS=',' read -ra IGNORE_PATHS <<< "${2:-}"

if [ ${#PATTERNS[@]} -eq 0 ]; then
    exit 0
fi

is_ignored_path() {
    local file="$1"
    for ignore_path in "${IGNORE_PATHS[@]}"; do
        ignore_path="${ignore_path#./}"
        if [ -n "$ignore_path" ] && [[ "$file" == "$ignore_path"* ]]; then
            return 0
        fi
    done
    return 1
}

matches_pattern() {
    local link="$1"
    for pattern in "${PATTERNS[@]}"; do
        # shellcheck disable=SC2053 # Intentional glob matching
        if [ -n "$pattern" ] && [[ "$link" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

git ls-files '*.md' | while read -r file; do
    if is_ignored_path "$file"; then
        continue
    fi
    grep -oE 'https?://[^][[:space:]()<>"`]+' "$file" | sed -E 's/[.,;:!?]+$//' | sort -u | while read -r link; do
        if ! matches_pattern "$link"; then
            continue
        fi
        if curl --silent --fail --location --output /dev/null --max-time 30 \
            --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36" \
            "$link"; then
            echo "[OK] $link ($file)"
        else
            echo "::warning file=$file::Link is not reachable: $link"
        fi
    done
done

exit 0
