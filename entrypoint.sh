#!/bin/bash
set -e

BUMP_TYPE=${INPUT_BUMP_TYPE}
GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
BASE_BRANCH=${INPUT_BASE_BRANCH}

git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

OUTPUT=$(python /action/increment_version.py "$BUMP_TYPE")
if [ $? -ne 0 ]; then
  echo "Error: Failed to increment version"
  exit 1
fi

CURRENT_VERSION=$(echo "$OUTPUT" | grep "Current version:" | sed 's/Current version: //')
NEW_VERSION=$(echo "$OUTPUT" | grep "New version:" | sed 's/New version: //')

if [ -z "$CURRENT_VERSION" ] || [ -z "$NEW_VERSION" ]; then
  echo "Error: Could not parse versions from script output"
  exit 1
fi

if ! git status --porcelain | grep -E "setup.py|pyproject.toml"; then
  echo "No changes to commit"
  exit 0
fi

git add setup.py pyproject.toml || true
git commit -m "Bump version to $NEW_VERSION"

git tag "v$NEW_VERSION"
git push origin "v$NEW_VERSION"

BRANCH_NAME="bump-version-to-$NEW_VERSION"
git checkout -b "$BRANCH_NAME"
git push origin "$BRANCH_NAME"

echo "$GITHUB_TOKEN" | gh auth login --with-token
gh pr create --base "$BASE_BRANCH" --head "$BRANCH_NAME" --title "Bump version to $NEW_VERSION" --body "This PR bumps the version from $CURRENT_VERSION to $NEW_VERSION."

echo "current_version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT
