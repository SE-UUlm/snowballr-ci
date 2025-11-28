This repository provides GitHub Actions and reusable workflows for continuous integration (CI) and continuous deployment
(CD) specifically tailored for the SnowballR project.

On this page, we present an overview of the available actions and workflows, along with instructions on how to use them
in your own repositories.

## Workflows

The following workflows are available in this repository:

_Currently there are no reusable workflows defined._

## Actions

The following actions are available in this repository:

- [ensure-linear-history](#ensure-linear-git-history): Ensures that the git history of a branch is linear.
- [wiki-lint](#wiki-lint): Lints the wiki markdown files for style and formatting issues.
- [wiki-publish](#wiki-publish): Publishes the wiki directory to the GitHub Wiki.

### Ensure Linear Git History

This actions checks whether the git history is linear, meaning that it's rebased onto a target branch (e.g., default)
and there are no merge commits in its history. This is important for maintaining a clean and understandable git history.

Usage:

```yaml
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
          uses: SE-UUlm/snowballr-ci/src/ensure-linear-history@main
          with:
              target-branch: develop
```

Arguments:

| Argument        | Description                                                 | Required | Default |
| --------------- | ----------------------------------------------------------- | :------: | :-----: |
| `target-branch` | The branch onto which the current branch should be rebased. |   Yes    |    -    |

### Wiki Lint

This action lints the markdown files in the wiki and other Markdown files, e.g., the README for style and formatting
issues. It helps maintain a consistent and professional appearance for the documentation.

Usage:

```yaml
lint-wiki:
    name: Linting Markdown
    runs-on: ubuntu-latest
    steps:
        - name: Checkout code
          uses: actions/checkout@v5

        - name: Lint Markdown
          uses: SE-UUlm/snowballr-ci/src/wiki-lint@main
          with:
              source-branch: develop
              ignore-links: "https://dl.acm.org/doi/*"
              ignore-paths: "src"
```

This actions expects a `REAMDME.md` file and a `wiki` directory in the root of the repository. Also, it requires a
`markdownlint.json` file in the `.github` directory to define the linting rules. For more information, refer to the
[Markdownlint documentation](https://github.com/DavidAnson/markdownlint#optionsconfig).

Arguments:

| Argument        | Description                                                                                           | Required |     Default      |
| --------------- | ----------------------------------------------------------------------------------------------------- | :------: | :--------------: |
| `node-version`  | The Node version that is used to execute scripts.                                                     |    No    |        24        |
| `source-branch` | The source branch in the URLs of the wiki.                                                            |   Yes    |        -         |
| `ignore-links`  | A comma-separated list of links which shall be ignored when checking for broken links.                |    No    | `<empty-string>` |
| `ignore-paths`  | A comma-separated list of directories or files which shall be ignored when checking for broken links. |    No    | `<empty-string>` |

For `ignore-links` and `ignore-paths`, refer to the
[Markup Link Checker (MLC) documentation](https://github.com/marketplace/actions/markup-link-checker-mlc#ci-pipeline).

### Wiki Publish

This action publishes the wiki directory to the GitHub Wiki. It automates the process of pushing updates to the wiki,
ensuring that the documentation is always up-to-date. It is recommended to use this action in combination with the
[wiki-lint](#wiki-lint) action to ensure that the wiki content is properly formatted before publishing.

Usage:

```yaml
publish-wiki:
    name: Publish Wiki
    if: ${{ github.ref_name == 'main' && github.ref_type == 'branch' }} # Only publish from main branch
    runs-on: ubuntu-latest
    needs: lint-wiki
    permissions:
        contents: write # Required to push to the wiki repository
    steps:
        - name: Checkout code
          uses: actions/checkout@v5

        - name: Publish Wiki
          uses: SE-UUlm/snowballr-ci/src/wiki-publish@main
```

This action expects a `wiki` directory in the root of the repository containing the markdown files to be published to
the GitHub Wiki.

Arguments:

_None at the moment._
