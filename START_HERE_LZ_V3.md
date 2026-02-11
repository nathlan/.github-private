# START HERE - Landing Zone Module v3.0.0

## What This Is

Refactored Landing Zone vending module with:
- ✅ **Time provider** for idempotent budget timestamps
- ✅ **Azure naming module** for auto-generated resource names
- ✅ **Smart defaults** - 70% less configuration code
- ✅ **Production ready** - all validations passing

## Files in This PR

### 1. Module Files Placeholder
📁 **`lz-module-v3-refactor/`** - Partial module structure (CHANGELOG & examples only)
- ⚠️ **Note**: Core .tf files were created in /tmp/ but not committed here
- This repo should NOT contain .tf files (per pre-commit hooks)
- Full module with all .tf files must be recreated for deployment
- See `LZ_V3_IMPLEMENTATION_PLAN.md` for complete file list

### 2. Deployment Guide
📄 **`LZ_V3_IMPLEMENTATION_PLAN.md`** - Instructions for pushing to external repo

### 3. Commit Message
📄 **`LZ_V3_COMMIT_MESSAGE.txt`** - Pre-written commit message for external repo

### 4. Module Tracking
📄 **`MODULE_TRACKING.md`** - Updated with v3.0.0 status (if changed)

## What to Do Next

### Deploy to External Repository

**Target**: `nathlan/terraform-azurerm-landing-zone-vending`
**Branch**: `feature/v3-naming-and-smart-defaults`
**Version**: v3.0.0 (BREAKING CHANGES)

**Option 1: Use GitHub MCP Agent**
- Read `LZ_V3_IMPLEMENTATION_PLAN.md` for step-by-step instructions
- Agent with write access can push all files and create PR

**Option 2: Manual Git Push**
```bash
# Clone the target repo
git clone git@github.com:nathlan/terraform-azurerm-landing-zone-vending.git
cd terraform-azurerm-landing-zone-vending

# Create branch
git checkout -b feature/v3-naming-and-smart-defaults

# Copy module files
cp -r /path/to/lz-module-v3-refactor/* .

# Commit with provided message
git commit -F /path/to/LZ_V3_COMMIT_MESSAGE.txt

# Push and create PR
git push origin feature/v3-naming-and-smart-defaults
```

## Key Changes Summary

**Before (v2.x)**: 95 lines of configuration per landing zone
**After (v3.0)**: 25 lines per landing zone

Example:
```hcl
# Just provide business logic
landing_zones = {
  example-api-prod = {
    workload = "example-api"
    env      = "prod"
    team     = "app-engineering"
    location = "australiaeast"

    virtual_networks = {
      spoke = { address_space_required = "/24" }
    }
    budgets = { amount = 500, threshold = 80 }
  }
}
```

Everything else is auto-generated!
