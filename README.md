# Bump Version Action

A GitHub Action to automatically bump the version in `setup.py` or `pyproject.toml`, commit the changes, tag the commit, and create a Pull Request (PR).

## Features
- Supports version bumping for Python projects using `setup.py` or `pyproject.toml`.
- Increments the version based on `major`, `minor`, or `patch` bump types.
- Commits the updated version file.
- Creates a new branch and pushes it to the repository.
- Opens a Pull Request with customizable labels.

## Inputs

| Name            | Description                                      | Required | Default   |
|-----------------|--------------------------------------------------|----------|-----------|
| `bump_type`     | Version bump type (`major`, `minor`, `patch`)    | Yes      | `patch`   |
| `github_token`  | GitHub token for committing and creating PR      | Yes      | -         |
| `base_branch`   | Base branch for the PR                           | No       | `main`    |
| `labels`        | Comma-separated labels to add to the PR          | No       | -         |

## Outputs

| Name              | Description                     |
|-------------------|---------------------------------|
| `current_version` | The version before bumping      |
| `new_version`     | The new version after bumping   |

## Usage

Add the following workflow to your `.github/workflows/bump-version.yml` file:

```yaml
name: Bump Version and Create PR

on:
  workflow_dispatch:
    inputs:
      bump_type:
        description: 'Version bump type'
        type: choice
        required: true
        default: 'patch'
        options:
          - major
          - minor
          - patch

permissions:
  contents: write
  pull-requests: write

jobs:
  bump-version:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Bump Version
        id: bump
        uses: iory/github-action-bump-version@v1.0.0
        with:
          bump_type: ${{ github.event.inputs.bump_type }}
          github_token: ${{ secrets.AUTO_MERGE_PAT }}
          base_branch: 'main'
          labels: 'auto-merge-ok,release'

      - name: Print Versions
        run: |
          echo "Current Version: ${{ steps.bump.outputs.current_version }}"
          echo "New Version: ${{ steps.bump.outputs.new_version }}"
```

### Example
To trigger the workflow manually:
1. Go to the "Actions" tab in your GitHub repository.
2. Select the "Bump Version" workflow.
3. Click "Run workflow" and choose the `bump_type` (e.g., `patch`).

This will:
- Bump the version (e.g., from `1.0.0` to `1.0.1` for a `patch` bump).
- Create a branch (e.g., `bump-version-to-1.0.1`).
- Commit the changes and push the branch.
- Open a PR with the specified labels.

## How It Works
1. **Version Detection**: The action checks for a version in `pyproject.toml` or `setup.py`.
2. **Version Increment**: Based on the `bump_type`, it increments the version (e.g., `1.0.0` → `1.1.0` for `minor`).
3. **File Update**: Updates the version in the respective file.
4. **Git Operations**: Commits the change, creates a branch, and pushes it to the remote repository.
5. **PR Creation**: Uses the GitHub CLI (`gh`) to create a Pull Request with the specified base branch and labels.

## Requirements
- A Python project with a version defined in either `setup.py` or `pyproject.toml`.
- A GitHub token with repository permissions (provided by `${{ secrets.GITHUB_TOKEN }}` in workflows).
