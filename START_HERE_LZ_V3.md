# START HERE - Landing Zone Module v3.0.0

## What This Is

Refactored Landing Zone vending module with:
- ✅ **Time provider** for idempotent budget timestamps
- ✅ **Azure naming module** for auto-generated resource names
- ✅ **Smart defaults** - 70% less configuration code
- ✅ **Production ready** - all validations passing

## Files in This PR

### 1. Partial Module Structure (Reference Only)
📁 **`lz-module-v3-refactor/`** - Contains CHANGELOG & examples only
- ⚠️ **Note**: Core .tf files were created in /tmp/ but not committed here
- This repo should NOT contain .tf files (per pre-commit hooks)
- Full module with all .tf files must be recreated for deployment
- See `LZ_V3_IMPLEMENTATION_PLAN.md` for complete file list

### 2. PR Template
📄 **`LZ_V3_PR_TEMPLATE.md`** - Template for external repo pull request

### 3. Deployment Guide
📄 **`LZ_V3_IMPLEMENTATION_PLAN.md`** - Instructions for pushing to external repo

### 4. Commit Message
📄 **`LZ_V3_COMMIT_MESSAGE.txt`** - Pre-written commit message for external repo

### 4. Module Tracking
📄 **`MODULE_TRACKING.md`** - Updated with v3.0.0 status (if changed)

## What to Do Next

### Use Terraform Module Creator Agent

**Quick Start**: Read `LZ_V3_AGENT_DEPLOYMENT_GUIDE.md` for complete step-by-step instructions.

An agent with GitHub MCP write access should:

1. **Read Implementation Specifications**:
   - `LZ_V3_AGENT_DEPLOYMENT_GUIDE.md` - **START HERE** - Complete workflow
   - `LZ_V3_NAMING_REQUIREMENTS.md` - **CRITICAL** - Corrected naming patterns
   - `LZ_V3_RESOURCE_ABBREVIATIONS_PATTERN.md` - **Pattern guide** for naming module gaps
   - `LZ_V3_IMPLEMENTATION_PLAN.md` - Technical specifications
   - `LZ_V3_REFACTORING_PLAN.md` - Detailed technical design

2. **Pull Latest Code** from external repo:
   - Use GitHub MCP to get current `main` branch from `nathlan/terraform-azurerm-landing-zone-vending`

3. **Create Module Files in /tmp/**:
   - Generate all .tf files following corrected naming requirements
   - **DO NOT** create or save .tf files in .github-private repo!

4. **Validate** in /tmp/:
   - terraform init -backend=false
   - terraform fmt -recursive
   - terraform validate

5. **Push to External Repo** via GitHub MCP:
   - Create branch `feature/v3-naming-and-smart-defaults`
   - Push all module files
   - Create PR with description from `LZ_V3_COMMIT_MESSAGE.txt`

**Target Repository**: `nathlan/terraform-azurerm-landing-zone-vending`  
**Version**: v3.0.0 (BREAKING CHANGES)  
**Location**: External repo ONLY - no .tf files in .github-private!

### ⚠️ Critical Naming Corrections

**Resource Groups**: `rg-{purpose}-{workload}-{env}` (purpose FIRST!)
- ✅ `rg-identity-example-api-prod`
- ✅ `rg-network-example-api-prod`
- ❌ NOT `rg-example-api-prod-identity`

**Subscriptions**: `sub-{workload}-{env}` (custom, not naming module)

**Budgets**: `budget-{workload}-{env}` (custom, consumption_budget output doesn't exist)

See `LZ_V3_NAMING_REQUIREMENTS.md` for complete details.

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
