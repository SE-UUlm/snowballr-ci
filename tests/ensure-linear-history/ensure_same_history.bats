#!/usr/bin/env bats

load '../test_helper'

SCRIPT="$BATS_TEST_DIRNAME/../../src/ensure-linear-history/ensure_same_history.sh"

setup() {
    setup_repo
    commit "chore: base"
    git branch -M main
    fetch_origin main
}

@test "When the current branch is rebased onto the target, then it passes" {
    git checkout -q -b feature
    commit "feat: add foo"

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
    [[ "$output" == *"has the same history"* ]]
}

@test "When the current branch has diverged from the target, then it fails" {
    git checkout -q -b feature
    commit "feat: add foo"
    # Advance main independently so the feature branch no longer contains its new tip
    git checkout -q main
    commit "chore: unrelated change on main"
    fetch_origin main
    git checkout -q feature

    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 1 ]
    [[ "$output" == *"::error::"* ]]
    [[ "$output" == *"rebase"* ]]
}

@test "When the current branch equals the target, then it passes" {
    run bash "$SCRIPT" -r origin main
    [ "$status" -eq 0 ]
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
