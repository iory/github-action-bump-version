#!/bin/bash
set -e

# Read input from environment variables
BUMP_TYPE=${INPUT_BUMP_TYPE}
GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
BASE_BRANCH=${INPUT_BASE_BRANCH}

echo "Bump type: $BUMP_TYPE"
echo "Base branch: $BASE_BRANCH"

# Configure git user
echo "Configuring git user..."
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Mark the directory as safe
echo "Marking directory as safe for git..."
git config --global --add safe.directory /github/workspace

# Run version increment script
echo "Running increment_version.py with bump type: $BUMP_TYPE"
OUTPUT=$(python /action/increment_version.py "$BUMP_TYPE")
if [ $? -ne 0 ]; then
  echo "Error: Failed to increment version"
  exit 1
fi
echo "Output from increment_version.py:"
echo "$OUTPUT"

CURRENT_VERSION=$(echo "$OUTPUT" | grep "Current version:" | sed 's/Current version: //')
NEW_VERSION=$(echo "$OUTPUT" | grep "New version:" | sed 's/New version: //')

echo "Parsed current version: $CURRENT_VERSION"
echo "Parsed new version: $NEW_VERSION"

if [ -z "$CURRENT_VERSION" ] || [ -z "$NEW_VERSION" ]; then
  echo "Error: Could not parse versions from script output"
  exit 1
fi

# Check for changes in relevant files
echo "Checking for changes in version files..."
if ! git status --porcelain | grep -E "setup.py|pyproject.toml"; then
  echo "No changes to commit"
  exit 0
fi

# Add and commit version changes
echo "Adding and committing changes..."
git add setup.py pyproject.toml || true
git commit -m "Bump version to $NEW_VERSION"

# Tagging and pushing tag
echo "Creating and pushing git tag v$NEW_VERSION..."
git tag "v$NEW_VERSION"
git push origin "v$NEW_VERSION"

# Create new branch and push
echo "Creating branch $BRANCH_NAME and pushing..."
BRANCH_NAME="bump-version-to-$NEW_VERSION"
git checkout -b "$BRANCH_NAME"
git push origin "$BRANCH_NAME"

# Authenticate gh CLI
echo "Authenticating gh CLI..."
echo "$GITHUB_TOKEN" | gh auth login --with-token

# Create Pull Request
echo "Creating Pull Request..."
gh pr create --base "$BASE_BRANCH" --head "$BRANCH_NAME" --title "Bump version to $NEW_VERSION" --body "This PR bumps the version from $CURRENT_VERSION to $NEW_VERSION."

# Output variables to GitHub Actions environment
echo "current_version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT

echo "All done!"
