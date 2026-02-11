# Landing Zone Module v3.0.0 - Refactoring Implementation Plan

## Executive Summary

This document outlines the complete refactoring plan for the terraform-azurerm-landing-zone-vending module to implement v3.0.0 with significant user experience improvements.

## Current State (v2.x - What's in Main Branch Now)

### Current Features (Already Implemented)
✅ IP address automation using Azure/avm-utl-network-ip-addresses
✅ Automatic address space calculation for VNets
✅ Basic wrapper around AVM pattern module
✅ Support for subscriptions, resource groups, role assignments
✅ Virtual networks with hub peering
✅ User-managed identities with federated credentials
✅ Budget creation

### Current Limitations (Problems to Solve)
❌ **No naming automation** - Users must manually name every resource
❌ **No time provider** - Budget dates must be manually managed
❌ **Flat variable structure** - Cannot manage multiple landing zones
❌ **Too much boilerplate** - Users repeat defaults for every field
❌ **No smart defaults** - Feature flags everywhere
❌ **Location repeated** - Users specify location in multiple places
❌ **Complex networking** - No subnet support, only VNet level config
❌ **Complex budget config** - Full time_grain, notifications objects required

### Current Interface Example
```hcl
# Current v2.x interface - 95+ lines per landing zone
location = "australiaeast"

subscription_alias_enabled = true
subscription_billing_scope = "BILLING_SCOPE"
subscription_display_name = "sub-example-api-dev"
subscription_alias_name = "sub-example-api-dev"
subscription_workload = "DevTest"
subscription_management_group_id = "Corp"
subscription_management_group_association_enabled = true
subscription_tags = {
  env = "dev"
  workload = "example-api"
  cost_centre = "IT-DEV-002"
  owner = "app-engineering"
}

resource_group_creation_enabled = true
resource_groups = {
  rg_identity = {
    name = "rg-example-api-identity"
    location = "australiaeast"
  }
  rg_network = {
    name = "rg-example-spoke-vnet"
    location = "australiaeast"
  }
}

virtual_network_enabled = true
virtual_networks = {
  spoke = {
    name = "vnet-example-api-dev"
    resource_group_key = "rg_network"
    address_space = ["10.100.0.0/24"]  # Or use IP automation
    location = "australiaeast"
    hub_peering_enabled = true
  }
}

umi_enabled = true
user_managed_identities = {
  plan = {
    name = "umi-example-api-dev-plan"
    resource_group_key = "rg_identity"
    location = "australiaeast"
    # ... role assignments, federated credentials
  }
  deploy = {
    name = "umi-example-api-dev-deploy"
    resource_group_key = "rg_identity"
    location = "australiaeast"
    # ... role assignments, federated credentials
  }
}

budget_enabled = true
budgets = {
  monthly = {
    name = "budget-example-api-dev"
    amount = 500
    time_grain = "Monthly"
    time_period_start = "2024-01-01T00:00:00Z"  # Manual dates!
    time_period_end = "2025-01-01T00:00:00Z"
    notifications = {
      threshold = {
        enabled = true
        operator = "GreaterThan"
        threshold = 80
        contact_emails = ["dev-team@example.com"]
      }
    }
  }
}
```

## Proposed State (v3.0.0 - What We're Building)

### New Features to Add
🎯 **Azure Naming Module Integration**
🎯 **Time Provider for Budget Timestamps**
🎯 **Landing Zones Map Structure**
🎯 **Smart Defaults for Everything**
🎯 **Auto-Generated Resource Names**
🎯 **Simplified Budget Configuration**
🎯 **Subnet Support in Virtual Networks**
🎯 **3-Layer Tag Merging**
🎯 **Environment Validation (dev/test/prod)**

### Proposed Interface (Clean Example)
```hcl
# Common variables (set once, apply to all landing zones)
subscription_billing_scope = "BILLING_SCOPE"
hub_network_resource_id = "HUB_VNET_ID"
subscription_management_group_id = "Corp"
github_organization = "nathlan"

# Common IP address space for all landing zones
base_address_space = "10.100.0.0/16"

tags = {
  managed_by = "terraform"
}

# Landing zones map - 25 lines per LZ!
landing_zones = {
  example-api-prod = {
    # Core identity (used to generate ALL resource names)
    workload = "example-api"
    env      = "prod"  # Validated: dev, test, or prod
    team     = "app-engineering"
    location = "australiaeast"

    # Optional: Override common tags
    subscription_tags = {
      cost_centre = "IT-DEV-002"
    }

    # Networking - simplified with subnets!
    virtual_networks = {
      spoke = {
        address_space_required = "/24"  # From base_address_space
        subnets = {
          default = { subnet_prefix = "/26" }
          api     = { subnet_prefix = "/28" }
        }
      }
    }

    # Budget - super simple!
    budgets = {
      amount         = 500
      threshold      = 80
      contact_emails = ["dev-team@example.com"]
    }

    # Federated credentials - just repository name!
    federated_credentials_github = {
      repository = "example-api-prod"
    }
  }
}
```

## Detailed Refactoring Plan

### 1. Networking Refactoring

#### Current Problems
- No subnet support
- Users specify location multiple times
- Complex address_space configuration
- No automatic subnet calculation

#### Proposed Solution
```hcl
# IN: landing_zones map
virtual_networks = {
  spoke = {
    address_space_required = "/24"  # Just the prefix size!
    subnets = {
      default = {
        name = "snet-default"  # Optional - auto-generated if not provided
        subnet_prefix = "/26"
      }
      api = {
        name = "snet-api"
        subnet_prefix = "/28"
      }
    }
  }
}

# OUT: Module calculates
# - VNet address: 10.100.0.0/24 (from base_address_space + IP automation)
# - Subnet default: 10.100.0.0/26 (first /26 in VNet)
# - Subnet api: 10.100.0.64/28 (next /28 after default)
# - VNet name: vnet-example-api-prod (from naming module)
# - Subnet names: snet-default, snet-api (from config or auto-generated)
```

#### Implementation Details
- Add subnet calculation logic in main.tf locals
- Use Azure naming module for VNet/subnet names
- Inherit location from landing zone
- Calculate subnet CIDRs from VNet address space

### 2. Azure Naming Module Integration

#### Implementation
```hcl
# versions.tf - Add naming module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.3"

  suffix = ["${each.value.workload}", "${each.value.env}"]
}

# main.tf - Use for all resources
resource "azurerm_subscription" "this" {
  subscription_name = module.naming.subscription.name  # sub-example-api-prod
  # ...
}

resource "azurerm_resource_group" "identity" {
  name = module.naming.resource_group.name_unique  # rg-example-api-prod-identity-abc123
  # ...
}

resource "azurerm_virtual_network" "spoke" {
  name = module.naming.virtual_network.name  # vnet-example-api-prod
  # ...
}

resource "azurerm_user_assigned_identity" "plan" {
  name = module.naming.user_assigned_identity.name  # umi-example-api-prod-plan
  # ...
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name = module.naming.consumption_budget.name  # budget-example-api-prod
  # ...
}
```

#### Resources to Name Automatically
- Subscriptions: `sub-{workload}-{env}`
- Resource Groups: `rg-{workload}-{env}-{purpose}` (identity, network)
- Virtual Networks: `vnet-{workload}-{env}`
- Subnets: `snet-{name}` (from config) or `snet-{workload}-{env}-{n}`
- User Managed Identities: `umi-{workload}-{env}-{purpose}` (plan, deploy)
- Budgets: `budget-{workload}-{env}`
- Federated Credentials: `oidc-gh-{repository}`

### 3. Time Provider for Budget Timestamps

#### Current Problem
Users must manually specify budget dates that become stale:
```hcl
time_period_start = "2024-01-01T00:00:00Z"
time_period_end = "2025-01-01T00:00:00Z"
```

#### Proposed Solution
```hcl
# In main.tf - time resources
resource "time_static" "budget" {
  for_each = var.landing_zones
}

resource "time_offset" "budget_end" {
  for_each = var.landing_zones

  base_offset_months = 12
  triggers = {
    start_date = time_static.budget[each.key].rfc3339
  }
}

# Use in budget resource
resource "azurerm_consumption_budget_subscription" "this" {
  for_each = var.landing_zones

  time_period {
    start_date = time_static.budget[each.key].rfc3339
    end_date   = time_offset.budget_end[each.key].rfc3339
  }
}
```

#### Benefits
- Budget timestamps are idempotent
- No manual date management
- Automatically renew on Terraform apply
- Consistent 12-month budget periods

### 4. Smart Defaults Implementation

#### Feature Flags - Default to Enabled
```hcl
# Old: User must enable everything
subscription_alias_enabled = true
resource_group_creation_enabled = true
virtual_network_enabled = true
umi_enabled = true
budget_enabled = true

# New: Enabled by default if config provided
# User just provides the config, module enables the feature
```

#### Default Resource Groups
```hcl
# Auto-create standard resource groups
resource_groups = {
  rg_identity = {
    # name auto-generated: rg-{workload}-{env}-identity
    # location inherited from landing zone
  }
  rg_network = {
    # name auto-generated: rg-{workload}-{env}-network
    # location inherited from landing zone
  }
}
```

#### Default User Managed Identities
```hcl
# Auto-create plan and deploy UMIs with sensible defaults
user_managed_identities = {
  plan = {
    # name: umi-{workload}-{env}-plan
    resource_group_key = "rg_identity"
    role_assignments = {
      subscription_reader = {
        role_definition_id_or_name = "Reader"
      }
    }
  }
  deploy = {
    # name: umi-{workload}-{env}-deploy
    resource_group_key = "rg_identity"
    role_assignments = {
      subscription_owner = {
        role_definition_id_or_name = "Owner"
      }
    }
  }
}
```

### 5. Landing Zones Map Structure

#### New Top-Level Structure
```hcl
variable "landing_zones" {
  type = map(object({
    # Core identity
    workload = string
    env      = string  # Validated: dev, test, or prod
    team     = string
    location = string

    # Optional: Subscription overrides
    subscription_devtest_enabled = optional(bool)  # Replaces subscription_workload
    subscription_tags            = optional(map(string), {})

    # Optional: Virtual networks
    virtual_networks = optional(map(object({
      address_space_required = string  # e.g., "/24"
      hub_peering_enabled    = optional(bool, true)
      subnets = optional(map(object({
        name          = optional(string)
        subnet_prefix = string
      })), {})
    })), {})

    # Optional: Budgets (simplified)
    budgets = optional(object({
      amount         = number
      threshold      = number
      contact_emails = list(string)
    }))

    # Optional: Federated credentials (simplified)
    federated_credentials_github = optional(object({
      repository = string
    }))
  }))

  validation {
    condition = alltrue([
      for lz_key, lz in var.landing_zones :
      contains(["dev", "test", "prod"], lz.env)
    ])
    error_message = "Each landing zone env must be 'dev', 'test', or 'prod'."
  }
}
```

### 6. Tag Merging Strategy

#### 3-Layer Merge
```hcl
# Layer 1: Common tags (applies to all)
tags = {
  managed_by = "terraform"
}

# Layer 2: Auto-generated tags (from landing zone identity)
auto_tags = {
  env      = lz.env
  workload = lz.workload
  owner    = lz.team
}

# Layer 3: Override tags (user-specified)
subscription_tags = {
  cost_centre = "IT-DEV-002"
}

# Final result (merge layer 1 + 2 + 3)
final_tags = {
  managed_by  = "terraform"
  env         = "prod"
  workload    = "example-api"
  owner       = "app-engineering"
  cost_centre = "IT-DEV-002"
}
```

### 7. Breaking Changes

#### Variable Changes
- ❌ Remove: `ip_address_automation_enabled` (always enabled)
- ❌ Remove: `ip_address_automation_address_space` → `base_address_space` (required)
- ❌ Remove: `ip_address_automation_vnet_prefix_sizes` (calculated from landing_zones)
- ❌ Remove: `subscription_workload` → `subscription_devtest_enabled` (boolean)
- ❌ Remove: All individual enable flags (smart defaults)
- ✅ Add: `landing_zones` map (new top-level structure)
- ✅ Add: `base_address_space` (required)
- ✅ Add: Time provider in versions.tf

#### Behavior Changes
- All resource names are auto-generated (cannot override)
- Budget timestamps auto-managed by time provider
- Resource groups always created (identity, network)
- UMIs always created (plan, deploy)
- Environment validation enforced (dev/test/prod only)

## File Structure

### Files to Modify
1. **versions.tf** - Add time provider requirement
2. **variables.tf** - Complete restructure with landing_zones map
3. **main.tf** - Add naming module, time resources, subnet logic
4. **outputs.tf** - Add outputs for calculated values
5. **README.md** - Complete rewrite with new examples
6. **CHANGELOG.md** - Add v3.0.0 entry

### Files to Keep Same
- LICENSE
- .gitignore
- .checkov.yml
- .tflint.hcl
- .terraform-docs.yml
- .github/workflows/release-on-merge.yml

## Implementation Steps

### Phase 1: Core Refactoring
1. Add time provider to versions.tf
2. Create new landing_zones variable structure
3. Integrate Azure naming module
4. Add time resources for budgets
5. Refactor main.tf to use landing_zones map

### Phase 2: Networking Enhancement
1. Add subnet support to virtual_networks
2. Implement subnet CIDR calculation
3. Auto-generate network resource names
4. Simplify address space configuration

### Phase 3: Smart Defaults
1. Remove all feature enable flags
2. Auto-create standard resource groups
3. Auto-create standard UMIs
4. Implement tag merging logic

### Phase 4: Simplification
1. Simplify budget configuration
2. Simplify federated credentials
3. Add environment validation
4. Replace subscription_workload with boolean

### Phase 5: Testing & Documentation
1. Validate all Terraform code
2. Run security scanning (Checkov)
3. Update README with new examples
4. Update CHANGELOG
5. Create migration guide

## Success Criteria

✅ 70% code reduction (95 → 25 lines per landing zone)
✅ All resource names auto-generated
✅ Budget timestamps automated with time provider
✅ Subnet support in virtual networks
✅ Smart defaults for all features
✅ Environment validation (dev/test/prod)
✅ 3-layer tag merging working
✅ All validations passing (fmt, validate, tflint, checkov)
✅ Complete documentation with examples
✅ Migration guide for v2.x users

## Migration Path for Existing Users

### Before (v2.x)
```hcl
module "landing_zone" {
  source = "nathlan/landing-zone-vending/azurerm"
  version = "~> 2.0"

  location = "australiaeast"
  subscription_alias_enabled = true
  # ... 95 more lines
}
```

### After (v3.0)
```hcl
module "landing_zones" {
  source = "nathlan/landing-zone-vending/azurerm"
  version = "~> 3.0"

  base_address_space = "10.100.0.0/16"

  landing_zones = {
    example-api-prod = {
      workload = "example-api"
      env = "prod"
      team = "app-engineering"
      location = "australiaeast"
      # ... 20 more lines (simplified)
    }
  }
}
```

## Validation Commands

```bash
# Initialize
terraform init -upgrade -backend=false

# Format
terraform fmt -recursive

# Validate
terraform validate

# Lint
tflint --init && tflint --recursive

# Security scan
checkov -d . --framework terraform --skip-path .terraform

# Generate docs
terraform-docs markdown table --output-file README.md --output-mode inject .
```

## Timeline Estimate

- Phase 1 (Core): 2-3 hours
- Phase 2 (Networking): 2-3 hours
- Phase 3 (Defaults): 2-3 hours
- Phase 4 (Simplification): 1-2 hours
- Phase 5 (Testing/Docs): 2-3 hours

**Total**: 9-14 hours of development work

## Deployment Strategy

1. Create feature branch: `feature/v3-naming-and-smart-defaults`
2. Implement all changes
3. Validate thoroughly
4. Create PR with breaking changes warning
5. Merge to main
6. Automated workflow creates v3.0.0 tag
7. Communicate breaking changes to users

## Questions to Resolve

1. ✅ Use time provider for budgets? **YES**
2. ✅ Allow subnet configuration? **YES**
3. ✅ Auto-generate all resource names? **YES**
4. ✅ Landing zones as map? **YES**
5. ✅ Validate environment (dev/test/prod)? **YES**

## Conclusion

This refactoring will transform the module from a thin wrapper with lots of boilerplate into a highly opinionated, user-friendly module that:

- **Reduces configuration by 70%**
- **Automates resource naming**
- **Manages budget timestamps automatically**
- **Supports subnets natively**
- **Provides smart defaults**
- **Enforces best practices**

The v3.0.0 release will be a breaking change, but the user experience improvement justifies the migration effort.
