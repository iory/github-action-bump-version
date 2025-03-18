#!/bin/bash
set -e

# Read inputs from arguments
BUMP_TYPE=$1
GITHUB_TOKEN=$2
BASE_BRANCH=$3
LABELS=$4

echo "Bump type: $BUMP_TYPE"
echo "Base branch: $BASE_BRANCH"
echo "Labels: $LABELS"

# Configure git user
echo "Configuring git user..."
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Mark directory as safe
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

# Check for changes
echo "Checking for changes in version files..."
if ! git status --porcelain | grep -E "setup.py|pyproject.toml"; then
  echo "No changes to commit"
  exit 0
fi

# Commit changes
echo "Adding and committing changes..."
git add setup.py pyproject.toml || true
git commit -m "Bump version to $NEW_VERSION"

# Create branch
BRANCH_NAME="bump-version-to-$NEW_VERSION"
echo "Creating branch $BRANCH_NAME and pushing..."
git checkout -b "$BRANCH_NAME"
git push origin "$BRANCH_NAME"

# Authenticate gh CLI
echo "Authenticating gh CLI..."
echo "$GITHUB_TOKEN" | gh auth login --with-token

# Create PR (add multiple labels if provided)
echo "Creating Pull Request..."

PR_CREATE_CMD="gh pr create --base \"$BASE_BRANCH\" --head \"$BRANCH_NAME\" --title \"Bump version to $NEW_VERSION\" --body \"This PR bumps the version from $CURRENT_VERSION to $NEW_VERSION.\""

# If LABELS is not empty, split by comma and append each label
if [ -n "$LABELS" ]; then
  IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
  for label in "${LABEL_ARRAY[@]}"; do
    PR_CREATE_CMD="$PR_CREATE_CMD --label \"$label\""
  done
fi

eval $PR_CREATE_CMD

# Output versions
echo "current_version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
echo "new_version=$NEW_VERSION" >> $GITHUB_OUTPUT

echo "All done!"
