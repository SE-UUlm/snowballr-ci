#!/usr/bin/env bats

load '../test_helper'

SCRIPT="$BATS_TEST_DIRNAME/../../src/ensure-conventional-commits/ensure_conventional_commits.sh"

setup() {
    setup_repo
    commit "chore: base"
    git branch -M main
    fetch_origin main
}

@test "When all commits are conventional, then it passes" {
    git checkout -q -b feature
    commit "feat(parser): add support for foo"
    commit "fix: correct off-by-one"

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
    [[ "$output" == *"follow the Conventional Commits specification"* ]]
}

@test "When a commit does not follow Conventional Commits, then it fails" {
    git checkout -q -b feature
    commit "feat(parser): add support for foo"
    commit "not a conventional commit"

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 1 ]
    [[ "$output" == *"::error::"* ]]
    [[ "$output" == *"not a conventional commit"* ]]
}

@test "When a commit has a breaking-change bang, then it passes" {
    git checkout -q -b feature
    commit "fix!: breaking change"

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
}

@test "When the only new commit is a merge commit, then it is excluded and passes" {
    git checkout -q -b other
    commit "fix: add bar"
    git checkout -q -b feature main
    commit "feat: add foo"
    git merge -q --no-edit other

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
}

@test "When the branch is up to date with the target, then it reports no commits and passes" {
    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
    [[ "$output" == *"No commits found"* ]]
}

@test "When a custom -t types list is given and the type is not included, then it fails" {
    git checkout -q -b feature
    commit "chore: bump deps"

    run bash "$SCRIPT" -r origin -t "feat,fix" main
    [ "$status" -eq 1 ]
}

@test "When the target branch is given as a positional argument, then it passes" {
    git checkout -q -b feature
    commit "feat: add foo"

    run bash "$SCRIPT" main
    [ "$status" -eq 0 ]
}
