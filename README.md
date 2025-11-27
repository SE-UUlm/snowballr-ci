# SnowballR CI

This is the CI repository for the SnowballR project where we maintain commonly used GitHub Actions workflows.
To learn more about the overall system, including its architecture, components, and how it facilitates systematic
literature reviews (SLRs) using snowballing, visit the [SnowballR repo](https://github.com/SE-UUlm/snowballr) and
its [wiki](https://github.com/SE-UUlm/snowballr/wiki).

## Workflows

The following workflows are available in this repository:

_There are no workflows defined at the moment._

## Actions

The following actions are available in this repository:

- [ensure-linear-history](#ensure-linear-git-history): Ensures that the git history of a pull request is linear.

### Ensure Linear Git History

This actions checks whether the git history is linear, meaning that there are no merge commits in the history. This is
important for maintaining a clean and understandable git history.

Usage:

```yaml
on:
    pull_request:
        branches:
            - develop

jobs:
    ensure-linear-history:
        name: Ensure Linear Git History
        runs-on: ubuntu-latest
        steps:
            - name: Checkout code
              uses: actions/checkout@v5
              with:
                  fetch-depth: 0
                  ref: ${{ github.head_ref }}

            - name: Run Check
              uses: SE-UUlm/snowballr-ci/src/git_conventions/ensure_linear_history@main
              with:
                  target-branch: develop
```

## Contributing

Contributions are welcome! If you have ideas for new workflows or improvements to existing ones, please feel free to
open an issue or submit a pull request.

### Reusable Workflows

A reusable workflow is a special type of GitHub Actions workflow that can be called from other workflows in different
repositories. This allows for better modularity and reusability of CI/CD processes across multiple projects.

You can find more information about reusable workflows in the
[GitHub documentation](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows).

If you want to use local scripts in your reusable workflow, you have to use composite actions. See the next
section for more details.

### Composite Actions

A composite action is a type of GitHub Action that allows you to combine multiple steps into a single action. This is
useful for encapsulating complex logic or reusing common sequences of steps across different workflows.

You can find more information about composite actions in the
[GitHub documentation](https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action).

If you want to calls a local script inside a composite action, you have to place the script inside the composite
action's directory. For example, if you have a script named `example_script.sh`, you would place it in the same
directory as your `action.yml` file for the composite action. Then, you can reference and execute the script in the
`runs` section of the `action.yml` file.

Here is an example of how to structure a composite action that calls a local script:

```yaml
name: "Example Composite Action"
description: "An example composite action that runs a local script"
inputs:
  example_input:
    description: "An example input"
    required: true
    default: "default value"
runs:
  using: "composite"
  steps:
    - name: Run local script
      shell: bash
      run: bash ${{ github.action_path }}/example_script.sh "${{ inputs.example_input }}"
```

`${{ github.action_path }}` is a special variable that points to the root directory of the composite action, allowing
you to easily reference local files within the action. Otherwise, the script would not be found when the action is
executed.
