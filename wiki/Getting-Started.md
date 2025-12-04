This repository provides GitHub Actions and reusable workflows for continuous integration (CI) and continuous deployment
(CD) specifically tailored for the SnowballR project.

On this page, we present an overview of the available actions and workflows, along with instructions on how to use them
in your own repositories.

## Workflows

The following workflows are available in this repository:

- [Docker Build and Publish](#docker-build-and-publish): Builds and publishes a Docker Image to the GitHub Container
  Registry.
- [Release](#release): Creates a new release on GitHub and optionally merges the current branch into a target branch.

### Docker Build and Publish

This reusable workflow builds and publishes a Docker Image to the GitHub Container Registry.

Usage:

```yaml
name: Docker

on:
    push:
        branches: ["develop"]
        tags: ["v*.*.*"]
    pull_request:

jobs:
    build-and-publish-docker-image:
        name: Build and Publish Docker Image
        uses: SE-UUlm/snowballr-ci/.github/workflows/docker.yml@v1
        permissions:
            contents: read
            packages: write
            attestations: write
            id-token: write
        with:
            default-branch: develop
```

This workflow expects a `Dockerfile` in the root of the repository.

Arguments:

| Argument         | Description                                                                           | Required | Default |
| ---------------- | ------------------------------------------------------------------------------------- | :------: | :-----: |
| `default-branch` | The default development branch on which the latest image is tagged with `latest-dev`. |   Yes    |    -    |

### Release

This reusable workflow creates a new release on GitHub and optionally merges the current branch into a target branch.

Usage:

```yaml
name: Release

on:
    push:
        tags: ["v*.*.*"]

jobs:
    release:
        name: Release Current Version
        uses: SE-UUlm/snowballr-ci/.github/workflows/release.yml@v1
        needs: build
        permissions:
            contents: write
        with:
            artifact-name: release-artifact-jar
            asset-path: release-artifact-*.jar
            target-branch: main

# Alternatively, if artifact contains multiple files:
        with:
            artifact-name: release-artifact
            asset-path: release-artifact.zip
            zip-assets: true
            target-branch: main
```

This reusable workflow expects a `CHANGELOG.md` in the root of the repository, which is used to create the release. Also,
the workflow has to be triggered on a tag push, because the tag is used to check which version is released.

Arguments:

| Argument        | Description                                                                             | Required |     Default      |
| --------------- | --------------------------------------------------------------------------------------- | :------: | :--------------: |
| `artifact-name` | The name of the artifact containing the release files.                                  |    No    | `<empty-string>` |
| `asset-path`    | The path to the release assets.                                                         |    No    | `<empty-string>` |
| `zip-assets`    | Whether the assets of the artifacts should be zipped before adding them to the release. |    No    |      false       |
| `target-branch` | The branch into which the current branch should be merged after creating the release.   |    No    | `<empty-string>` |

If `artifact-name` and `asset-path` are provided, the specified artifact is downloaded and its assets attached to the
release. If `zip-assets` is set to `true`, the assets are zipped into a single file before attaching them to the
release. In this case, the `asset-path` refers to the name of the zip file. If `target-branch` is provided, the current
branch is merged into the specified target branch after creating the release.
Otherwise, no merge is performed.

## Actions

The following actions are available in this repository:

- [Ensure Linear Git History](#ensure-linear-git-history): Ensures that the git history of a branch is linear.
- [Markdown Lint](#markdown-lint): Lints Markdown files for style and formatting issues.
- [Wiki Publish](#wiki-publish): Publishes the wiki directory to the GitHub Wiki.
- [Teamscale Upload](#teamscale-upload): Uploads code coverage reports to Teamscale.

### Ensure Linear Git History

This action checks whether the git history is linear, meaning that it's rebased onto a target branch (e.g., default)
and there are no merge commits in its history. This is important for maintaining a clean and understandable git history.

Usage:

```yaml
ensure-linear-history:
    name: Ensure Linear Git History
    runs-on: ubuntu-latest
    steps:
        - name: Checkout repository
          uses: actions/checkout@v6
          with:
              fetch-depth: 0
              ref: ${{ github.head_ref }}

        - name: Run Check
          uses: SE-UUlm/snowballr-ci/src/ensure-linear-history@v1
          with:
              target-branch: develop
```

Arguments:

| Argument        | Description                                                 | Required | Default |
| --------------- | ----------------------------------------------------------- | :------: | :-----: |
| `target-branch` | The branch onto which the current branch should be rebased. |   Yes    |    -    |

### Markdown Lint

This action lints the Markdown files in the wiki and other files, e.g., the README.md and CHANGELOG.md for style and
formatting issues. It helps maintain a consistent and professional appearance for the documentation.

Usage:

```yaml
lint-md:
    name: Linting Markdown
    runs-on: ubuntu-latest
    steps:
        - name: Checkout repository
          uses: actions/checkout@v6

        - name: Lint Markdown
          uses: SE-UUlm/snowballr-ci/src/lint-md@v1
          with:
              source-branch: develop
              ignore-links: "https://dl.acm.org/doi/*"
              ignore-paths: "src"
```

A `markdownlint.json` file in the `.github` directory to define the linting rules is required. For more
information, refer to the [Markdownlint documentation](https://github.com/DavidAnson/markdownlint#optionsconfig).

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
[Markdown Lint](#markdown-lint) action to ensure that the wiki content is properly formatted before publishing.

Usage:

```yaml
publish-wiki:
    name: Publish Wiki
    if: github.ref_name == 'main' && github.ref_type == 'branch' # Only publish from main branch
    runs-on: ubuntu-latest
    needs: lint-md
    permissions:
        contents: write # Required to push to the wiki repository
    steps:
        - name: Checkout repository
          uses: actions/checkout@v6

        - name: Publish Wiki
          uses: SE-UUlm/snowballr-ci/src/wiki-publish@v1
```

This action expects a `wiki` directory in the root of the repository containing the markdown files to be published to
the GitHub Wiki.

Arguments:

_None at the moment._

### Teamscale Upload

This action uploads code coverage reports to Teamscale, a code quality and coverage analysis tool. It helps in
monitoring and improving the code quality by providing insights into code coverage metrics.

The action is designed to have sensible defaults for SnowballR projects, but it can be customized using the provided
arguments.

Usage:

```yaml
teamscale-upload:
    name: Teamscale Upload
    runs-on: ubuntu-latest
    needs: coverage-report
    steps:
        - name: Checkout repository
          uses: actions/checkout@v6

        - name: Download coverage report
          uses: actions/download-artifact@v6
          with:
              name: coverage-report
              path: .

        - name: Teamscale Upload
          uses: SE-UUlm/snowballr-ci/src/teamscale-upload@v1
          with:
              project: <project-id>
              access-key: ${{ secrets.TEAMSCALE_ACCESS_KEY }}
              format: <format>
              files: coverage-report.xml
```

In the example above, we assume that there is a previous job named `coverage-report` that generates the coverage report
and uploads it as an artifact named `coverage-report`.

Arguments:

| Argument     | Description                                                                                     | Required |                    Default                     |
| ------------ | ----------------------------------------------------------------------------------------------- | :------: | :--------------------------------------------: |
| `server`     | The URL of the Teamscale server.                                                                |    No    | <https://exia.informatik.uni-ulm.de/teamscale> |
| `project`    | The Teamscale project ID where the coverage report should be uploaded.                          |   Yes    |                       -                        |
| `user`       | The Teamscale username for authentication.                                                      |    No    |                slartibartfass2                 |
| `access-key` | The Teamscale access key for authentication. It is recommended to store this in GitHub Secrets. |   Yes    |                       -                        |
| `format`     | The format of the coverage report.                                                              |   Yes    |                       -                        |
| `files`      | The path(s) or pattern(s) of the coverage report files.                                         |   Yes    |                       -                        |

All arguments are passed to the [Teamscale Upload Action](https://github.com/cqse/teamscale-upload-action), refer to
[its documentation](https://github.com/cqse/teamscale-upload-action/blob/master/action.yml) for more details.
