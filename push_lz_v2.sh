#!/bin/bash
# Script to push Landing Zone v2.0.0 changes to external repository
# This script should be run manually since we don't have write access via MCP

set -e

echo "================================================"
echo "Landing Zone Module v2.0.0 Update Script"
echo "================================================"
echo ""

# Configuration
REPO_URL="git@github.com:nathlan/terraform-azurerm-landing-zone-vending.git"
BRANCH="feature/add-ip-address-automation"
SOURCE_DIR="/tmp/lz-module-update"
TEMP_CLONE="/tmp/lz-repo-clone"

echo "Step 1: Verifying source files exist..."
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory $SOURCE_DIR not found!"
    exit 1
fi

echo "✅ Source files found in $SOURCE_DIR"
echo ""

echo "Step 2: Cloning repository..."
rm -rf "$TEMP_CLONE"
git clone "$REPO_URL" "$TEMP_CLONE"
cd "$TEMP_CLONE"

echo "✅ Repository cloned"
echo ""

echo "Step 3: Checking out feature branch..."
git checkout "$BRANCH"
echo "✅ On branch: $(git branch --show-current)"
echo ""

echo "Step 4: Copying updated files..."
# Core Terraform files
cp "$SOURCE_DIR/main.tf" .
cp "$SOURCE_DIR/variables.tf" .
cp "$SOURCE_DIR/outputs.tf" .
cp "$SOURCE_DIR/versions.tf" .
cp "$SOURCE_DIR/README.md" .

# Configuration files
cp "$SOURCE_DIR/.tflint.hcl" .
cp "$SOURCE_DIR/.checkov.yml" .
cp "$SOURCE_DIR/.terraform-docs.yml" .
cp "$SOURCE_DIR/.gitignore" .

echo "✅ Files copied"
echo ""

echo "Step 5: Showing changes..."
git status
echo ""

echo "Step 6: Reviewing changes..."
git diff main.tf | head -50
echo ""

read -p "Do you want to commit and push these changes? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted by user"
    exit 1
fi

echo ""
echo "Step 7: Committing changes..."
git add main.tf variables.tf outputs.tf versions.tf README.md .tflint.hcl .checkov.yml .terraform-docs.yml .gitignore
git commit -m "BREAKING: Make IP automation default, prevent address reordering

- Remove backward compatibility - IP automation is now DEFAULT
- Set address_prefix_efficient_mode = false to prevent address changes
- Rename variables: base_address_space, vnet_prefix_sizes (both required)
- Remove address_space from virtual_networks type (always calculated)
- Simplify module logic - no conditional IP calculation

BREAKING CHANGES:
- base_address_space and vnet_prefix_sizes are now required
- virtual_networks.address_space removed from type (always auto-calculated)
- No opt-out of IP automation

This is v2.0.0 - see README for migration guide."

echo "✅ Changes committed"
echo ""

echo "Step 8: Pushing to GitHub..."
git push origin "$BRANCH"

echo ""
echo "================================================"
echo "✅ SUCCESS! Changes pushed to PR #5"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Review the PR at: https://github.com/nathlan/terraform-azurerm-landing-zone-vending/pull/5"
echo "2. Run CI/CD validation"
echo "3. Update PR description to reflect v2.0.0 breaking changes"
echo "4. Consider if this should be a new PR since it's a breaking change"
echo ""
