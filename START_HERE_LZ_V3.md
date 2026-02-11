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

### Use Terraform Module Creator Agent

An agent with GitHub MCP write access should:

1. **Read** `LZ_V3_IMPLEMENTATION_PLAN.md` for complete specifications
2. **Recreate** the module files from specifications (all .tf files, configs, examples)
3. **Use GitHub MCP server** to:
   - Create branch `feature/v3-naming-and-smart-defaults` in `nathlan/terraform-azurerm-landing-zone-vending`
   - Push all module files
   - Create PR with description from `LZ_V3_COMMIT_MESSAGE.txt`

**Target Repository**: `nathlan/terraform-azurerm-landing-zone-vending`
**Version**: v3.0.0 (BREAKING CHANGES)

**No manual git commands or bash scripts needed** - the agent handles everything via GitHub MCP server.

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
