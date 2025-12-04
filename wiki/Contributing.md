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

If you want to call a local script inside a composite action, you have to place the script inside the composite
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

## Release procedure

We create a new release whenever a set of features, bug fixes, or changes is ready to be deployed.
To release a new version of the CI, follow the steps in the
[SnowballR Wiki](https://github.com/SE-UUlm/snowballr/wiki/Contributing#release-procedure).

Make sure that the examples in [Getting Started](https://github.com/SE-UUlm/snowballr-ci/wiki/Getting-Started) use the
latest major version of this repository.
