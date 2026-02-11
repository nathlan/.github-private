# AGENT INSTRUCTIONS: Deploy LZ v3.0.0 to External Repository

## For: terraform-module-creator Agent

This document provides step-by-step instructions for deploying the Landing Zone v3.0.0 module to the external repository.

## Prerequisites

- GitHub MCP server with write access enabled
- Ability to call tools: create_branch, push_files, create_pull_request (or equivalents)

## Critical Rules

### ❌ DO NOT
- Create or save ANY .tf files in this `.github-private` repository
- Use bash git commands to clone/push to external repos  
- Leave module files in /tmp/ and consider work complete
- Assume files created in /tmp/ will persist between sessions

### ✅ DO
- Use GitHub MCP server for ALL external repo operations
- Pull latest code from external repo before making changes
- Create all module files in /tmp/ directory
- Validate all files (terraform init/fmt/validate)
- Push all changes to external repository via GitHub MCP
- Create PR in external repository (not this repo)

## Step-by-Step Workflow

### Step 1: Read All Specification Documents
```
Required reading in order:
1. START_HERE_LZ_V3.md - Overview and quick start
2. LZ_V3_NAMING_REQUIREMENTS.md - CRITICAL naming patterns (READ FIRST!)
3. LZ_V3_IMPLEMENTATION_PLAN.md - Complete specifications
4. LZ_V3_REFACTORING_PLAN.md - Technical details
5. LZ_V3_COMMIT_MESSAGE.txt - Pre-written commit message
```

### Step 2: Pull Latest Code from External Repo
```
Tool: github-mcp-server-get_file_contents
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  path: / (or specific files: main.tf, variables.tf, etc.)
  ref: main

Purpose: Get current v2.x code as base for understanding structure
```

### Step 3: Create Module Files in /tmp/
```
Directory: /tmp/terraform-azurerm-landing-zone-vending-v3/

Files to create (15 total):
1. versions.tf - Add time provider requirement
2. variables.tf - landing_zones map structure
3. main.tf - Naming module, time resources, module calls
4. outputs.tf - All outputs
5. README.md - Documentation
6. CHANGELOG.md - v3.0.0 entry
7. LICENSE - MIT license
8. .gitignore - Standard Terraform
9. .checkov.yml - Security scanning
10. .tflint.hcl - Linting config
11. .terraform-docs.yml - Docs config
12. .github/workflows/release-on-merge.yml - CI/CD
13. examples/basic/main.tf - Example usage
14. examples/basic/versions.tf - Example providers
15. examples/basic/README.md - Example docs

⚠️ CRITICAL: Follow naming patterns from LZ_V3_NAMING_REQUIREMENTS.md
```

### Step 4: Validate Files in /tmp/
```
Commands to run in /tmp/terraform-azurerm-landing-zone-vending-v3/:

terraform init -backend=false
terraform fmt -recursive
terraform validate

Optional (if tools available):
terraform-docs markdown table --output-file README.md --output-mode inject .
```

### Step 5: Push to External Repo
```
Tool: github-mcp-server-push_files (or equivalent)
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  branch: feature/v3-naming-and-smart-defaults (NEW branch)
  base: main
  message: (Use content from LZ_V3_COMMIT_MESSAGE.txt)
  files: [array of {path, content} for all 15 files]

Note: Some MCP implementations may require creating branch first,
      then pushing files. Adapt as needed for your MCP server version.
```

### Step 6: Create Pull Request
```
Tool: github-mcp-server-create_pull_request (or equivalent)
Parameters:
  owner: nathlan
  repo: terraform-azurerm-landing-zone-vending
  title: feat: v3.0.0 - Azure naming integration and smart defaults (BREAKING)
  body: (See PR template section below)
  head: feature/v3-naming-and-smart-defaults
  base: main
  draft: false

Pull request should be ready for review (not draft).
```

### Step 7: Verify Success
```
Check that PR was created in external repo:
https://github.com/nathlan/terraform-azurerm-landing-zone-vending/pulls

Verify:
- [ ] Branch exists in external repo
- [ ] All 15 files are present
- [ ] PR is created with comprehensive description
- [ ] No .tf files were created in .github-private repo
```

## Critical Naming Patterns

### Resource Abbreviations Pattern

**IMPORTANT**: Before implementing, review Azure naming module:
https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

For resource types NOT in the naming module, use locals with configurable abbreviations:

```hcl
# ========================================
# Resource Abbreviations (Internal to Module)
# ========================================
# These abbreviations are for resource types NOT in Azure naming module.
# Platform team can update these centrally without breaking user configurations.
# NOT exposed via variables/tfvars - internal to module only.

locals {
  resource_abbreviations = {
    subscription   = "sub"
    budget         = "budget"
    resource_group = "rg"
    # Add other custom abbreviations as needed after reviewing naming module
  }
}
```

**Why This Pattern:**
- ✅ Platform team can update abbreviations centrally in module code
- ✅ Consistency across all landing zones
- ✅ NOT exposed via tfvars (users cannot override)
- ✅ Easy to maintain if organizational standards change

### Resource Groups (Custom)
```hcl
# Pattern: {abbreviation}-{purpose}-{workload}-{env}
# Purpose comes FIRST!
# Uses abbreviation from locals

resource_groups = {
  rg_identity = {
    name = "${local.resource_abbreviations.resource_group}-identity-${each.value.workload}-${each.value.env}"
  }
  rg_network = {
    name = "${local.resource_abbreviations.resource_group}-network-${each.value.workload}-${each.value.env}"
  }
}

# Examples:
#   ✅ rg-identity-example-api-prod
#   ✅ rg-network-example-api-prod
#   ❌ rg-example-api-prod-identity (WRONG!)
```

### Subscriptions (Custom)
```hcl
# Pattern: {abbreviation}-{workload}-{env}
# NOT from naming module
# Uses abbreviation from locals

locals {
  subscription_names = {
    for lz_key, lz in var.landing_zones : 
      lz_key => "${local.resource_abbreviations.subscription}-${lz.workload}-${lz.env}"
  }
}

# Example: sub-example-api-prod
```

### Budgets (Custom)
```hcl
# Pattern: {abbreviation}-{workload}-{env}
# NOT from naming module (consumption_budget output doesn't exist)
# Uses abbreviation from locals

budgets = {
  monthly = {
    name = "${local.resource_abbreviations.budget}-${each.value.workload}-${each.value.env}"
    # ...
  }
}

# Example: budget-example-api-prod
```

### Other Resources (Naming Module)
```hcl
# Use Azure naming module for:
# - Virtual Networks
# - Subnets
# - User Assigned Identities

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.3"
  
  for_each = var.landing_zones
  suffix   = [each.value.workload, each.value.env]
}

# Examples:
virtual_networks = {
  spoke = {
    name = module.naming[each.key].virtual_network.name
    # Generates: vnet-example-api-prod
  }
}

user_managed_identities = {
  plan = {
    name = "${module.naming[each.key].user_assigned_identity.name}-plan"
    # Generates: id-example-api-prod-plan
  }
}
```

### Role Assignments (Subscription Scope)
```hcl
# ALWAYS use empty relative_scope for subscription scope

user_managed_identities = {
  plan = {
    role_assignments = {
      subscription_reader = {
        definition     = "Reader"
        relative_scope = ""  # Empty = subscription scope
      }
    }
  }
  deploy = {
    role_assignments = {
      subscription_owner = {
        definition     = "Owner"
        relative_scope = ""  # Empty = subscription scope
      }
    }
  }
}
```

## PR Description Template

```markdown
# Landing Zone Module v3.0.0 - Azure Naming Integration and Smart Defaults

## Breaking Changes

This is a MAJOR version release with breaking changes. Existing users will need to migrate their configurations.

## Key Features

- **Azure Naming Module Integration**: All resources (except subscriptions/budgets/RGs) use Azure naming conventions
- **Time Provider for Budgets**: Idempotent budget timestamps using time_static and time_offset
- **Smart Defaults**: 70% code reduction (95 → 22 lines per landing zone)
- **Landing Zones Map**: Support multiple landing zones in single module call
- **Flattened Networking**: Simplified VNet structure (always 1 spoke per LZ)
- **Subnet Support**: Automatic CIDR calculation from VNet address space
- **Environment Validation**: Only dev, test, or prod allowed
- **3-Layer Tag Merging**: Common + auto-generated + custom tags

## Naming Patterns

### Custom Naming (NOT in naming module)
- **Subscriptions**: `sub-{workload}-{env}`
- **Resource Groups**: `rg-{purpose}-{workload}-{env}` (purpose FIRST!)
- **Budgets**: `budget-{workload}-{env}`

### Azure Naming Module
- **Virtual Networks**: `vnet-{workload}-{env}`
- **Subnets**: `snet-{workload}-{env}-{name}`
- **User Assigned Identities**: `id-{workload}-{env}-{purpose}`

## Migration Required

Existing v2.x users must:
1. Add time provider to versions.tf
2. Restructure to landing_zones map
3. Remove manual resource naming
4. Update budget configuration format
5. Update VNet configuration (flattened)

See CHANGELOG.md for detailed migration guide.

## Validation

✅ terraform init -backend=false  
✅ terraform fmt -recursive  
✅ terraform validate  
✅ All naming patterns verified

## Breaking Changes Summary

- New `landing_zones` map variable structure
- Time provider required (hashicorp/time >= 0.9, < 1.0)
- Auto-generated resource names (cannot override)
- Environment validation enforced (dev/test/prod only)
- Subscription scope for UMI role assignments
```

## Troubleshooting

### If GitHub MCP Write Tools Not Available

If you don't see create_branch, push_files, or create_pull_request tools:

1. **Document what's available**: List all github-mcp-server-* tools you can see
2. **Research alternatives**: Use github-mcp-server-github_support_docs_search to find write operation docs
3. **Report inability**: Clearly state which write operations are missing
4. **Provide files**: At minimum, output all file contents so they can be manually deployed

### If Module Already Exists in External Repo

1. Check existing branches with github-mcp-server-list_branches
2. If feature/v3-naming-and-smart-defaults exists, use a different branch name
3. Consider: feature/v3-naming-corrected or feature/v3-smart-defaults-v2

### If Validation Fails

1. Review error messages carefully
2. Check LZ_V3_NAMING_REQUIREMENTS.md for correct patterns
3. Verify Azure naming module outputs exist (don't assume)
4. Test with simplified example first

## Success Criteria

✅ PR created in nathlan/terraform-azurerm-landing-zone-vending  
✅ All 15 files present in PR  
✅ Naming patterns match requirements exactly  
✅ No .tf files in .github-private repo  
✅ Terraform validation passes  
✅ PR ready for review (not draft)

## Final Notes

- This is a complex refactor - take time to read all specifications
- Naming patterns are critical - double-check against LZ_V3_NAMING_REQUIREMENTS.md
- External repo deployment is mandatory - /tmp/ is ephemeral
- Use GitHub MCP for all external repo operations - no bash git commands

**When in doubt, refer back to LZ_V3_NAMING_REQUIREMENTS.md!**
