#!/bin/bash
# Script to push the refactored landing zone vending module to GitHub
# Run this from the root of the terraform-azurerm-landing-zone-vending repository

set -e

REPO_ROOT=$(pwd)
SOURCE_DIR="/tmp/terraform-azurerm-landing-zone-vending-refactor"
BRANCH_NAME="feature/naming-and-smart-defaults"
BASE_BRANCH="feature/add-ip-address-automation"

echo "=== Landing Zone Vending Module Refactoring Push Script ==="
echo ""
echo "This script will:"
echo "  1. Create branch: ${BRANCH_NAME}"
echo "  2. Copy refactored files from: ${SOURCE_DIR}"
echo "  3. Commit changes"
echo "  4. Push to origin"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Verify we're in a git repository
if [ ! -d .git ]; then
    echo "ERROR: Not in a git repository root"
    exit 1
fi

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Checkout base branch and create new branch
echo "Creating branch ${BRANCH_NAME} from ${BASE_BRANCH}..."
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"
git checkout -b "$BRANCH_NAME"

# Remove old files (except .git and .terraform)
echo "Cleaning existing files..."
find . -maxdepth 1 -type f -not -name ".git*" -not -name ".terraform*" -delete
rm -rf examples .github 2>/dev/null || true

# Copy new files
echo "Copying refactored files..."
cp -r "$SOURCE_DIR"/* .
cp -r "$SOURCE_DIR"/.github .
cp "$SOURCE_DIR"/.gitignore .
cp "$SOURCE_DIR"/.checkov.yml .
cp "$SOURCE_DIR"/.tflint.hcl .
cp "$SOURCE_DIR"/.terraform-docs.yml .

# Show status
echo ""
echo "Changes to be committed:"
git status

# Commit
echo ""
read -p "Commit these changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Branch ${BRANCH_NAME} created but not committed."
    exit 1
fi

git add .
git commit -m "refactor: integrate Azure naming and smart defaults

Major refactoring to provide clean interface with automatic naming,
smart defaults, and 70% code reduction.

- Integrate Azure naming module for automatic resource names
- Add landing_zones map variable for multi-LZ support
- Auto-enable features based on configuration
- Simplify budget, VNet, and OIDC configuration
- Add environment validation (dev/test/prod only)
- Support subscription_devtest_enabled boolean

Breaking changes: Complete interface redesign
See CHANGELOG.md for full details"

# Push
echo ""
read -p "Push to origin? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Committed locally but not pushed."
    echo "To push later, run: git push origin ${BRANCH_NAME}"
    exit 0
fi

git push origin "$BRANCH_NAME"

echo ""
echo "=== SUCCESS ==="
echo "Branch pushed: ${BRANCH_NAME}"
echo ""
echo "Next steps:"
echo "  1. Go to GitHub: https://github.com/nathlan/terraform-azurerm-landing-zone-vending"
echo "  2. Create Pull Request"
echo "  3. Base: ${BASE_BRANCH}"
echo "  4. Compare: ${BRANCH_NAME}"
echo "  5. Use the PR template from: /tmp/REFACTORING_COMPLETE_MANUAL_PUSH_REQUIRED.md"
echo ""
