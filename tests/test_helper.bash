# Shared setup for tests that exercise scripts against a real git history.
#
# Scripts under test resolve a target branch via "<remote>/<branch>" (e.g. origin/main).
# To exercise that without a real network remote, each test repo adds itself as its own
# "origin" (a local path remote) and fetches from it, exactly as a CI checkout would.

# Creates an empty git repo in a fresh per-test tmp dir and cds into it.
setup_repo() {
    repo="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$repo"
    cd "$repo" || return 1
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git config commit.gpgsign false
    git remote add origin .
}

# Fetches the given branch from the self-remote "origin" so "origin/<branch>" resolves.
fetch_origin() {
    git fetch -q origin "$1"
}

# Creates an empty commit with the given message.
commit() {
    git commit -q --allow-empty -m "$1"
}
