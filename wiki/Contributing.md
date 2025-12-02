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
To release a new version of the ci repo, follow these steps:

1. Create a release branch for the release:

   ```bash
   git checkout -b releases/vX.Y.Z
   ```

   Replace `X`, `Y`, `Z` with the correct version numbers according to semantic versioning.

2. Add an entry to the *CHANGELOG.md*. Prefer using [hallmark](https://github.com/vweevers/hallmark) to add the entry:

   ```bash
   hallmark cc add major|minor|patch
   ```

   Follow the guidelines of [Common Changelog](https://common-changelog.org/), i.e. especially use imperative mood.

   > **Note**: To use hallmark locally install it globally with `npm install -g hallmark`

3. Commit and push changes to the *CHANGELOG.md*.

4. Create a pull request and request a review, so the *CHANGELOG.md* syntax and content is validated.

5. After the pull request is merged, create a tag with the same version - so "vX.Y.Z" - at the merge commit.

   ```bash
   git pull origin/main
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

   Then the CI automatically creates the release.
