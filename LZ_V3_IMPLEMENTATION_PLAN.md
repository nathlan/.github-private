# Landing Zone Module v3.0.0 - Implementation Plan

## ⚠️ CRITICAL: External Repository Deployment Required

**ALL module files MUST be created and pushed to the external repository:**
- **Target Repo**: `nathlan/terraform-azurerm-landing-zone-vending`
- **NO .tf files** can be left in this `.github-private` repository
- **Work in /tmp/** is ephemeral and will be lost between sessions

## Agent Workflow

The terraform-module-creator agent MUST follow this workflow:

### 1. Pull Latest Code from External Repo
```
Use GitHub MCP server to get current main branch from:
  nathlan/terraform-azurerm-landing-zone-vending

This provides the base for making changes.
```

### 2. Create Module Files in /tmp/
```
Create all 15 module files in a temporary directory:
  /tmp/terraform-azurerm-landing-zone-vending-v3/

DO NOT create or modify ANY .tf files in .github-private repo!
```

### 3. Validate All Files
```
Run validations in /tmp/ directory:
  - terraform init -backend=false
  - terraform fmt -recursive  
  - terraform validate
  - terraform-docs (if available)
```

### 4. Push to New Branch in External Repo
```
Use GitHub MCP server to:
  - Create branch: feature/v3-naming-and-smart-defaults
  - Push all files from /tmp/ to external repo
  - Create pull request

ALL changes must go to external repository!
```

### 5. Clean Up
```
/tmp/ files will be lost after session ends.
This is expected and correct - external repo is source of truth.
```

## Instructions for Agent

This document contains complete specifications for the terraform-module-creator agent to:
1. **Pull** latest code from external repo via GitHub MCP
2. **Recreate** all module files from these specifications in /tmp/
3. **Validate** all files (fmt, validate, etc.)
4. **Push** changes to new branch in external repo via GitHub MCP
5. **Create PR** in external repo for v3.0.0 release

## Why This Workflow?

- `.tf` files are correctly blocked by pre-commit hooks in .github-private
- Files in /tmp/ are ephemeral (lost between sessions)
- **External repository** (`nathlan/terraform-azurerm-landing-zone-vending`) is the source of truth
- **Agent MUST use GitHub MCP** to interact with external repo
- No manual git commands or local clones needed

## Status
✅ Module design complete and validated
✅ Naming requirements corrected (see LZ_V3_NAMING_REQUIREMENTS.md)
✅ Ready for agent to recreate and deploy to external repo

## Mission
Use terraform-module-creator agent to recreate and push the refactored terraform-azurerm-landing-zone-vending module to GitHub as v3.0.0 with breaking changes.

## Target Repository
- **Repo**: `nathlan/terraform-azurerm-landing-zone-vending`
- **Base Branch**: `main` (current v2.x with IP automation)
- **New Branch**: `feature/v3-naming-and-smart-defaults`
- **Target Version**: v3.0.0 (MAJOR release with breaking changes)

## ⚠️ CORRECTED Naming Requirements

**READ FIRST**: See `LZ_V3_NAMING_REQUIREMENTS.md` for full details.

### Use Azure Naming Module
- ✅ Virtual Networks: `module.naming[].virtual_network.name`
- ✅ Subnets: `module.naming[].subnet.name`
- ✅ User Assigned Identities: `module.naming[].user_assigned_identity.name` + suffix

### Use Custom Naming (NOT in naming module)
- ❌ **Subscriptions**: `sub-{workload}-{env}` (custom local)
- ❌ **Budgets**: `budget-{workload}-{env}` (consumption_budget output doesn't exist)
- ❌ **Resource Groups**: `rg-{purpose}-{workload}-{env}` (purpose prefix FIRST)

### Critical: Resource Group Pattern
```hcl
# ✅ CORRECT
resource_groups = {
  rg_identity = {
    name = "rg-identity-${each.value.workload}-${each.value.env}"
  }
  rg_network = {
    name = "rg-network-${each.value.workload}-${each.value.env}"
  }
}

# Examples:
#   rg-identity-example-api-prod  ✅
#   rg-network-example-api-prod   ✅
#   
#   rg-example-api-prod-identity  ❌ WRONG
```

### Role Assignments
```hcl
# Always at subscription scope
role_assignments = {
  subscription_reader = {
    definition     = "Reader"
    relative_scope = ""  # Empty = subscription scope
  }
}
```

## Module Specifications

The module must be recreated with these specifications:

### Core Files (15 files total)
1. `main.tf` - Module logic with time provider and Azure naming
2. `variables.tf` - Simplified interface with landing_zones map
3. `outputs.tf` - All outputs
4. `versions.tf` - Includes time provider requirement
5. `README.md` - Complete documentation
6. `CHANGELOG.md` - v3.0.0 details
7. `LICENSE` - MIT license
8. `.gitignore` - Standard Terraform ignores
9. `.checkov.yml` - Security scanning config
10. `.tflint.hcl` - Linting config
11. `.terraform-docs.yml` - Documentation config
12. `.github/workflows/release-on-merge.yml` - CI/CD workflow
13. `examples/basic/main.tf` - Example usage
14. `examples/basic/README.md` - Example documentation
15. `examples/basic/versions.tf` - Example providers

## GitHub MCP Server Implementation Steps

### Step 1: Test Write Access
```
Use: github-mcp-server-list_branches
Repo: nathlan/terraform-azurerm-landing-zone-vending
Expected: List of branches including main
```

### Step 2: Create New Branch
```
Tool: github-mcp-server-create_branch (if available)
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  branch: feature/v3-naming-and-smart-defaults
  from_branch: main
```

### Step 3: Push All Files
```
Tool: github-mcp-server-push_files (if available)
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  branch: feature/v3-naming-and-smart-defaults
  message: "feat: v3.0.0 - Azure naming integration and smart defaults with time provider (BREAKING)"
  files: [array of {path: string, content: string}]
```

### Step 4: Create Pull Request
```
Tool: github-mcp-server-create_pull_request (if available)
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  title: "feat: v3.0.0 - Azure naming integration and smart defaults (BREAKING)"
  body: [See PR_TEMPLATE section below]
  head: feature/v3-naming-and-smart-defaults
  base: main
  draft: false
```

## Commit Message

```
feat: v3.0.0 - Azure naming integration and smart defaults with time provider (BREAKING)

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

Migration required for existing users. See README and CHANGELOG for details.
```

## PR Description Template

See file: `/home/runner/work/.github-private/.github-private/LZ_V3_PR_TEMPLATE.md`

## Key Changes Summary

### 1. Time Provider for Budgets
- Uses `time_static` and `time_offset` resources
- Budget timestamps are idempotent
- No manual date management needed

### 2. Azure Naming Module
- Integrated `Azure/naming/azurerm ~> 0.4.3`
- All resource names auto-generated
- Consistent naming convention

### 3. Smart Defaults
- 70% code reduction (95 → 25 lines)
- All feature flags enabled automatically
- Clean, business-focused interface

### 4. Breaking Changes
- New `landing_zones` map variable structure
- Time provider required in versions
- Cannot override auto-generated names
- Environment validation (dev/test/prod)

## Validation Status
✅ terraform init -upgrade -backend=false
✅ terraform fmt -recursive
✅ terraform validate
✅ tflint --recursive (0 issues)
✅ checkov (Passed: 5, Failed: 0)
✅ terraform-docs generated

## Post-Deployment Actions
1. Verify PR created successfully in external repository
2. Review changes in GitHub UI
3. Merge when approved (or request reviews)
4. Automated workflow will create v3.0.0 tag
5. Update MODULE_TRACKING.md in .github-private repo

## Agent Instructions Summary

The terraform-module-creator agent should:

1. **Read this entire document** to understand specifications
2. **Use agent instructions** from `.github/agents/terraform.agent.md`
3. **Create module files** following the specifications below
4. **Validate** all files (fmt, validate, tflint, checkov)
5. **Use GitHub MCP server tools** to:
   - Create branch `feature/v3-naming-and-smart-defaults`
   - Push all files to `nathlan/terraform-azurerm-landing-zone-vending`
   - Create pull request with message from `LZ_V3_COMMIT_MESSAGE.txt`

**No bash scripts or manual git needed** - agent handles everything autonomously.

## Success Criteria

✅ Branch `feature/v3-naming-and-smart-defaults` created
✅ All 15 files pushed to branch
✅ PR created with comprehensive description
✅ PR shows 70% code reduction
✅ All CI checks pass
✅ Ready for review and merge
