#!/bin/bash
# Automated deployment script for Landing Zone Module v3.0.0

set -e

REPO_URL="git@github.com:nathlan/terraform-azurerm-landing-zone-vending.git"
SOURCE_DIR="/tmp/terraform-azurerm-landing-zone-vending-refactor"
WORK_DIR="/tmp/lz-deploy-$$"

echo "🚀 Deploying Landing Zone Module v3.0.0"
echo "========================================"

# Validate source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ ERROR: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Clone repository
echo "📥 Cloning repository..."
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# Create new branch
echo "🌿 Creating branch feature/v3-naming-and-smart-defaults..."
git fetch origin
git checkout -b feature/v3-naming-and-smart-defaults origin/feature/add-ip-address-automation

# Copy all files
echo "📋 Copying refactored module files..."
rsync -av --delete --exclude='.git' --exclude='.terraform' "$SOURCE_DIR/" ./

# Stage all changes
echo "➕ Staging changes..."
git add .

# Show summary
echo ""
echo "�� Changes summary:"
git status --short | head -20
echo ""

# Confirm before committing
read -p "Continue with commit and push? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted by user"
    cd /tmp
    rm -rf "$WORK_DIR"
    exit 1
fi

# Commit
echo "💾 Committing..."
git commit -m "feat: v3.0.0 - Azure naming integration and smart defaults with time provider (BREAKING)

Complete refactor of landing zone vending module with time provider for budgets.

Key Features:
- Integrate Azure naming module (Azure/naming/azurerm ~> 0.4.3)
- Use time provider for idempotent budget timestamps (time_static + time_offset)
- Implement smart defaults (70% code reduction)
- Auto-generate all resource names
- Support multiple landing zones via landing_zones map
- Replace subscription_workload with subscription_devtest_enabled
- Simplify budget configuration (amount/threshold/emails only)
- Add virtual network subnet support
- Implement 3-layer tag merging
- Simplify federated credentials (just repository name)

BREAKING CHANGES:
- New landing_zones map variable structure
- Time provider required (hashicorp/time >= 0.9, < 1.0)
- Cannot override auto-generated resource names
- Environment validation (dev/test/prod only)
- IP automation at common level (base_address_space)
- Virtual networks use address_space_required (e.g., '/24')

Migration required for existing users. See README and CHANGELOG for details."

# Push
echo "⬆️  Pushing to GitHub..."
git push origin feature/v3-naming-and-smart-defaults

echo ""
echo "✅ SUCCESS! Branch pushed to GitHub"
echo ""
echo "📝 Next steps:"
echo "1. Go to: https://github.com/nathlan/terraform-azurerm-landing-zone-vending/pull/new/feature/v3-naming-and-smart-defaults"
echo "2. Create PR to main or feature/add-ip-address-automation"
echo "3. Use PR template from /tmp/PR_TEMPLATE.md"
echo ""
echo "Cleaning up..."
cd /tmp
rm -rf "$WORK_DIR"
echo "Done! 🎉"
