#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../src/ensure-conventional-branches/ensure_conventional_branches.sh"

@test "When the branch has a valid feat type, then it passes" {
    run bash "$SCRIPT" "feat/1-branch-name"
    [ "$status" -eq 0 ]
    [[ "$output" == *"follows the expected naming convention"* ]]
}

@test "When the branch has a valid fix type, then it passes" {
    run bash "$SCRIPT" "fix/2-branch-name"
    [ "$status" -eq 0 ]
}

@test "When the slug has multiple hyphenated words, then it passes" {
    run bash "$SCRIPT" "chore/12-bump-deps-a-lot"
    [ "$status" -eq 0 ]
}

@test "When the type is not in the allowed list, then it fails" {
    run bash "$SCRIPT" "feature/1-branch-name"
    [ "$status" -eq 1 ]
    [[ "$output" == *"::error::"* ]]
}

@test "When the branch has no slash separator, then it fails" {
    run bash "$SCRIPT" "feat-1-branch-name"
    [ "$status" -eq 1 ]
}

@test "When the branch has no issue number, then it fails" {
    run bash "$SCRIPT" "feat/branch-name"
    [ "$status" -eq 1 ]
}

@test "When the branch has no conventional prefix at all, then it fails" {
    run bash "$SCRIPT" "main"
    [ "$status" -eq 1 ]
}

@test "When the branch matches the default releases ignore pattern, then it is skipped" {
    run bash "$SCRIPT" "releases/v1.1.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"skipping check"* ]]
}

@test "When the branch matches the default dependabot ignore pattern, then it is skipped" {
    run bash "$SCRIPT" "dependabot/github_actions/actions/checkout-7"
    [ "$status" -eq 0 ]
    [[ "$output" == *"skipping check"* ]]
}

@test "When a custom -t types list is given and the type is not included, then it fails" {
    run bash "$SCRIPT" -t "feat,fix" "chore/3-something"
    [ "$status" -eq 1 ]
}

@test "When a custom -i ignore pattern matches the branch, then it is skipped" {
    run bash "$SCRIPT" -i "wip/*" "wip/anything-goes"
    [ "$status" -eq 0 ]
}

@test "When branch-name is missing, then usage is printed and it fails" {
    run bash "$SCRIPT"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "When -h is given, then usage is printed and it exits successfully" {
    run bash "$SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}
