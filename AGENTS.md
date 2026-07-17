# AGENTS

## Overview

This repository contains the **shared GitHub Actions** for the SnowballR project: reusable workflows under
`.github/workflows/` and composite actions under `src/`. Other SnowballR repositories consume these via
`uses: SE-UUlm/snowballr-ci/...@<tag>` (versioned by major: `@v1`, or by exact tag for `release.yml`).
Prefer referencing the wiki and existing docs over restating them here. If you must summarize, keep it short
and point to the canonical page.

### SnowballR repositories

- Organization: https://github.com/SE-UUlm
- SnowballR (umbrella repo): https://github.com/SE-UUlm/snowballr
- SnowballR API: https://github.com/SE-UUlm/snowballr-api
- SnowballR Backend: https://github.com/SE-UUlm/snowballr-backend
- SnowballR Frontend: https://github.com/SE-UUlm/snowballr-frontend
- SnowballR CI: https://github.com/SE-UUlm/snowballr-ci
- SnowballR Mock Backend: https://github.com/SE-UUlm/snowballr-mock-backend
- SnowballR Backend (legacy): https://github.com/SE-UUlm/snowballr-backend-old

### Canonical documentation and what each covers

- README.md — repository overview and pointers
- wiki/Home.md — wiki entry page
- wiki/Getting-Started.md — usage reference for every reusable workflow and composite action, including
  argument tables and YAML snippets
- wiki/Contributing.md — guidance for adding new reusable workflows and composite actions; release procedure

## Structure

```
.
├── src/                                # composite actions (one directory per action)
│   ├── ensure-linear-history/          # action.yml + shell helpers (ensure_*.sh)
│   ├── ensure-conventional-commits/    # action.yml + ensure_conventional_commits.sh
│   ├── ensure-conventional-branches/   # action.yml + ensure_conventional_branches.sh
│   ├── lint-md/                        # action.yml + replace-github-urls.js
│   ├── teamscale-upload/               # action.yml + retrieve_last_commit.sh
│   └── wiki-publish/                   # action.yml + add_auto_gen_wiki_hint.sh
├── .github/workflows/          # reusable workflows + this repo's own CI
│   ├── docker.yml              # reusable: build + publish Docker image to ghcr.io
│   ├── release.yml             # reusable: create GitHub release from CHANGELOG.md
│   ├── release-ci.yml          # this-repo: cuts the release and updates the major-version tag
│   ├── git_conventions.yml     # this-repo: linear history, commit, and branch-name checks on PRs
│   ├── test.yml                # this-repo: runs the bats suite in tests/ on PRs
│   └── wiki.yml                # this-repo: markdown lint + publish wiki/
├── tests/                              # bats tests, mirroring src/'s directory structure
│   ├── test_helper.bash                # shared setup helpers (self-remote git repos, etc.)
│   ├── ensure-linear-history/          # ensure_linear_history.bats + ensure_same_history.bats
│   ├── ensure-conventional-commits/    # ensure_conventional_commits.bats
│   └── ensure-conventional-branches/   # ensure_conventional_branches.bats
├── wiki/                       # canonical documentation
├── images/                     # logo used in README
├── markdownlint.json
├── CHANGELOG.md
└── LICENSE
```

## Where to look

| Task                                      | Location                                               | Notes                                                                                              |
| ----------------------------------------- | ------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| Project overview                          | README.md                                              | High-level pointers.                                                                               |
| Usage docs for every workflow/action      | wiki/Getting-Started.md                                | Argument tables, YAML examples, defaults.                                                          |
| Contributing reusable workflows / actions | wiki/Contributing.md                                   | Composite action patterns, `${{ github.action_path }}`, release procedure.                         |
| Reusable: build & publish Docker image    | .github/workflows/docker.yml                           | Input: `default-branch` (tagged `latest-dev`). Used by api/frontend/etc.                           |
| Reusable: release with CHANGELOG.md       | .github/workflows/release.yml                          | Inputs: `artifact-name`, `asset-path`, `zip-assets`, `target-branch`.                              |
| This-repo release                         | .github/workflows/release-ci.yml                       | Cuts releases for this repo; also updates the major-version-only tag (`v1`, ...).                  |
| Action: ensure linear git history         | src/ensure-linear-history/action.yml                   | Checks rebase onto a target branch; no merge commits in history.                                   |
| Action: ensure conventional commits       | src/ensure-conventional-commits/action.yml             | Checks every commit subject against the Conventional Commits spec.                                 |
| Action: ensure conventional branches      | src/ensure-conventional-branches/action.yml            | Checks branch name against `<type>/<issue-number>-<slug>`; default ignore for releases/dependabot. |
| Action: markdown lint + link check        | src/lint-md/action.yml                                 | Wraps `markdownlint-cli` + `markup-link-checker`; ignore-paths/links inputs.                       |
| Action: publish wiki/ to GitHub Wiki      | src/wiki-publish/action.yml                            | Expects a `wiki/` dir in the repo; adds an auto-generated hint.                                    |
| Action: upload coverage to Teamscale      | src/teamscale-upload/action.yml                        | Defaults for SnowballR Teamscale; required: `project`, `access-key`, `format`, `files`.            |
| Tests for the shell scripts               | tests/<action-name>/*.bats                             | bats, mirrors src/ layout; git-history tests use a self-remote (`git remote add origin .`).        |
| Release procedure (canonical)             | https://github.com/SE-UUlm/snowballr/wiki/Contributing | Single source of truth for SnowballR releases.                                                     |

## Architecture and patterns

- **Reusable workflow vs composite action:** Reusable workflows live in `.github/workflows/` and are called
  via `uses: SE-UUlm/snowballr-ci/.github/workflows/<file>.yml@<ref>` (typically a tag). Composite actions
  live in `src/<name>/action.yml` and are called via `uses: SE-UUlm/snowballr-ci/src/<name>@<ref>`. See
  wiki/Contributing.md for the rationale (composite actions are required for local scripts).
- **Local scripts in composite actions:** Use `${{ github.action_path }}` to reference scripts that live next
  to the action's `action.yml` (e.g. `bash ${{ github.action_path }}/example_script.sh`). Without this, the
  script is not on the runner's path.
- **Versioning of references:** Consumers pin by major version (`@v1`) for the reusable workflows and composite
  actions; the umbrella repo pins exact tags for `release.yml@v1.1.0`. The release pipeline in `release-ci.yml`
  re-points the major-version tag (`v1`) at the latest minor/patch release.

## Boundaries

- Always do: prefer wiki references for usage docs; keep the input contract of existing actions/workflows
  backwards-compatible within the same major version; document any new input in wiki/Getting-Started.md;
  update the wiki examples to the **latest major version** of this repo as part of releases (wiki/Contributing.md).
- Ask first: any breaking change to inputs/outputs of an existing action or reusable workflow (would bump
  major); changes to the major-version-only tag logic in `release-ci.yml`; adding new GitHub secrets/permissions
  to actions; changes to the default Teamscale server URL or user.
- Never do: commit secrets / Teamscale access keys / tokens; use `actions/*@<sha-of-an-untrusted-fork>`;
  introduce hard-coded paths that assume a consumer repo's layout (use inputs instead); push to consumer repos
  from these actions.

## Commands (run from repo root)

There is no local build for this repo. Validation happens via:

- The reusable workflows / composite actions themselves running in consumer repos.
- This repo's own CI (`wiki.yml` for markdown, `git_conventions.yml` for git conventions, `test.yml` for the
  bats suite in `tests/`).
- Locally: `bats --recursive tests/` (requires `bats-core`, e.g. `npm install -g bats`) runs the same suite as
  `test.yml`.
- Releases: tag `v*.*.*` on `main` to trigger `release-ci.yml`, which runs `release.yml` and updates the
  major-version tag.

### Releasing a new version

1. Follow the canonical release procedure: https://github.com/SE-UUlm/snowballr/wiki/Contributing#release-procedure
   (create a `releases/vX.Y.Z` branch, update `CHANGELOG.md` with `hallmark cc add ...`, open a PR).
2. Update the YAML snippets in `wiki/Getting-Started.md` to reference the new latest major version if needed
   (wiki/Contributing.md).
3. After merging, tag `vX.Y.Z` on the merge commit and push — CI cuts the release and bumps the `vN` tag.

## Style, checks, and tests

- **Style:** Follow `markdownlint.json` for all wiki / README / CHANGELOG content.
- **Shell scripts:** Keep them POSIX-friendly where possible; place them next to the consuming `action.yml`.
- **Unit tests:** `src/*/*.sh` scripts that touch git history or plain string checks have `bats` tests under
  `tests/<action-name>/` (mirroring `src/<action-name>/`, one `*.bats` file per script), with shared repo-setup
  helpers in `tests/test_helper.bash`; run via `test.yml` on every PR. Scripts that mainly wrap third-party
  actions (lint-md, wiki-publish, teamscale-upload) are still validated only by consumer repos' CI.

## Issues

- Use `.github/ISSUE_TEMPLATE` (when present) to pick the right template.

## PRs

- Use `.github/pull_request_template.md` (when present) for required sections.

## Git and CI conventions

- PRs to `main` must keep a linear git history, follow Conventional Commits, and be named
  `<type>/<issue-number>-<slug>` (`git_conventions.yml`, using this repo's own `src/ensure-linear-history`,
  `src/ensure-conventional-commits`, and `src/ensure-conventional-branches` actions — note that it dogfoods its
  own actions).
- Releases tag `v*.*.*` on `main`; the major-version-only tag is updated automatically (`release-ci.yml`).

## Conventional commits

Commit messages follow Conventional Commits with a short type prefix and optional scope. Common types in this
repo include: feat, fix, refactor, docs, chore, ci. Use lowercase types and keep the subject imperative and
concise.
