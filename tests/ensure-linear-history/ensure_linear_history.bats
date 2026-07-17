#!/usr/bin/env bats

load '../test_helper'

SCRIPT="$BATS_TEST_DIRNAME/../../src/ensure-linear-history/ensure_linear_history.sh"

setup() {
    setup_repo
    commit "chore: base"
    git branch -M main
    fetch_origin main
}

@test "When there are no merge commits since the target, then it passes" {
    git checkout -q -b feature
    commit "feat: add foo"
    commit "fix: add bar"

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
    [[ "$output" == *"No merge commits found"* ]]
}

@test "When the current branch equals the target, then it passes" {
    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
}

@test "When the target branch was merged into the current branch, then it fails" {
    git checkout -q -b feature
    commit "feat: add foo"
    git checkout -q main
    commit "chore: unrelated change on main"
    fetch_origin main
    git checkout -q feature
    git merge -q --no-edit main

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 1 ]
    [[ "$output" == *"::error::"* ]]
    [[ "$output" == *"merged"* ]]
}

@test "When any merge commit exists since the target, even of an unrelated sibling branch, then it fails" {
    # Both branches fork from the same target tip, so the merge's first parent
    # still contains the target as an ancestor - the check has no notion of a
    # "safe" merge, it flags any merge commit found since the target.
    git checkout -q -b other
    commit "fix: add bar"
    git checkout -q -b feature main
    commit "feat: add foo"
    git merge -q --no-edit other

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 1 ]
    [[ "$output" == *"::error::"* ]]
}

@test "When the branch is given as a positional argument, then it passes" {
    git checkout -q -b feature
    commit "feat: add foo"

    run bash "$SCRIPT" main
    [ "$status" -eq 0 ]
}

@test "When -h is given, then usage is printed and it exits successfully" {
    run bash "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}
