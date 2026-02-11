# Landing Zone Module v3.0.0 - Naming Requirements

## Critical Naming Specifications

This document provides the **CORRECTED** naming requirements for the Landing Zone v3.0.0 module.

## Azure Naming Module vs Custom Prefixes

**IMPORTANT**: Always check the Azure naming module outputs to see what's available:
https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

### Resource Abbreviations for Naming Module Gaps

For resource types NOT supported by the Azure naming module, use a **locals block** with configurable abbreviations:

```hcl
# ========================================
# Resource Abbreviations (Internal to Module)
# ========================================
# These abbreviations are for resource types NOT in the Azure naming module.
# Platform team can update these centrally without breaking user configurations.
# NOT exposed via variables - internal to module only.

locals {
  # Resource abbreviations for types not in Azure naming module
  resource_abbreviations = {
    subscription   = "sub"
    budget         = "budget"
    resource_group = "rg"
    # Add other custom abbreviations as needed
  }
}

# Usage example:
# name = "${local.resource_abbreviations.subscription}-${workload}-${env}"
# Result: sub-example-api-prod
```

**Key Principles:**
- ✅ **DO**: Define abbreviations in `locals` block (platform team can update)
- ✅ **DO**: Keep abbreviations internal to module code
- ❌ **DON'T**: Expose abbreviations as variables (users should NOT override)
- ❌ **DON'T**: Hardcode abbreviations directly in naming patterns

**Why This Pattern:**
- Allows platform team to update abbreviations centrally
- Maintains consistency across all landing zones
- Easy to change if organizational standards evolve
- Users get consistent naming without configuration burden

### ✅ Use Azure Naming Module (Azure/naming/azurerm ~> 0.4.3)

The following resources use the Azure naming module with suffix `[workload, env]`:

- **Virtual Networks**: `module.naming[].virtual_network.name`
  - Generated format: `vnet-{workload}-{env}`
  - Example: `vnet-example-api-prod`

- **Subnets**: `module.naming[].subnet.name`
  - Generated format: `snet-{workload}-{env}-{purpose}`
  - Example: `snet-example-api-prod-default`

- **User Assigned Identities**: `module.naming[].user_assigned_identity.name`
  - Generated format: `id-{workload}-{env}` (then append `-plan` or `-deploy`)
  - Example: `id-example-api-prod-plan`, `id-example-api-prod-deploy`

### ❌ DO NOT Use Naming Module (Custom Prefixes)

The following resources require **CUSTOM naming** because they are NOT available in the Azure naming module:

#### 1. Subscriptions
```hcl
# Use resource abbreviations from locals
local.subscription_names = {
  for lz_key, lz in var.landing_zones : 
    lz_key => "${local.resource_abbreviations.subscription}-${lz.workload}-${lz.env}"
}

# Format: {abbreviation}-{workload}-{env}
# Example: sub-example-api-prod
```

#### 2. Budgets
```hcl
# Use resource abbreviations from locals
name = "${local.resource_abbreviations.budget}-${each.value.workload}-${each.value.env}"

# Format: {abbreviation}-{workload}-{env}
# Example: budget-example-api-prod
```

**Note**: The Azure naming module does NOT have a `consumption_budget` output. Verify at:
https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

#### 3. Resource Groups ⚠️ CRITICAL CORRECTION
```hcl
# Use resource abbreviations from locals with PURPOSE PREFIX
resource_groups = {
  rg_identity = {
    name = "${local.resource_abbreviations.resource_group}-identity-${each.value.workload}-${each.value.env}"
  }
  rg_network = {
    name = "${local.resource_abbreviations.resource_group}-network-${each.value.workload}-${each.value.env}"
  }
}

# Format: {abbreviation}-{purpose}-{workload}-{env}
# Examples: 
#   rg-identity-example-api-prod
#   rg-network-example-api-prod
```

**⚠️ IMPORTANT**: The purpose (`identity`, `network`) comes FIRST, before workload and env.

**❌ WRONG**: `rg-example-api-prod-identity`  
**✅ CORRECT**: `rg-identity-example-api-prod`

## Implementation Pattern

### In main.tf

```hcl
# ========================================
# Resource Abbreviations (Internal)
# ========================================

locals {
  # Resource abbreviations for types NOT in Azure naming module
  # Platform team can update these - NOT exposed to end users via tfvars
  resource_abbreviations = {
    subscription   = "sub"
    budget         = "budget"
    resource_group = "rg"
  }
}

# ========================================
# Azure Naming Module (per landing zone)
# ========================================

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.3"

  for_each = var.landing_zones
  suffix   = [each.value.workload, each.value.env]
}

# ========================================
# Custom Naming (not in naming module)
# ========================================

locals {
  # Subscriptions (using abbreviation from locals)
  subscription_names = {
    for lz_key, lz in var.landing_zones : 
      lz_key => "${local.resource_abbreviations.subscription}-${lz.workload}-${lz.env}"
  }
}

# ========================================
# Landing Zone Module Call
# ========================================

module "landing_zone" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "~> 0.1.0"

  for_each = var.landing_zones
  location = each.value.location

  # Subscription (using abbreviation from locals)
  subscription_display_name = local.subscription_names[each.key]
  subscription_alias_name   = local.subscription_names[each.key]

  # Resource groups (using abbreviation from locals with purpose prefix)
  resource_groups = {
    rg_identity = {
      name     = "${local.resource_abbreviations.resource_group}-identity-${each.value.workload}-${each.value.env}"
      location = each.value.location
    }
    rg_network = {
      name     = "${local.resource_abbreviations.resource_group}-network-${each.value.workload}-${each.value.env}"
      location = each.value.location
    }
  }

  # Virtual network (naming module)
  virtual_networks = {
    spoke = {
      name = module.naming[each.key].virtual_network.name
      # ... other config
    }
  }

  # User Managed Identities (naming module + suffix)
  user_managed_identities = {
    plan = {
      name = "${module.naming[each.key].user_assigned_identity.name}-plan"
      # ... other config
    }
    deploy = {
      name = "${module.naming[each.key].user_assigned_identity.name}-deploy"
      # ... other config
    }
  }

  # Budgets (using abbreviation from locals)
  budgets = {
    monthly = {
      name = "${local.resource_abbreviations.budget}-${each.value.workload}-${each.value.env}"
      # ... other config
    }
  }
}
```

## Role Assignments Configuration

Role assignments for User Managed Identities are ALWAYS at subscription scope:

```hcl
user_managed_identities = {
  plan = {
    name               = "${module.naming[each.key].user_assigned_identity.name}-plan"
    resource_group_key = "rg_identity"
    location           = each.value.location

    role_assignments = {
      subscription_reader = {
        definition     = "Reader"
        relative_scope = ""  # Empty string = subscription scope
      }
    }
  }

  deploy = {
    name               = "${module.naming[each.key].user_assigned_identity.name}-deploy"
    resource_group_key = "rg_identity"
    location           = each.value.location

    role_assignments = {
      subscription_owner = {
        definition     = "Owner"
        relative_scope = ""  # Empty string = subscription scope
      }
    }
  }
}
```

## Naming Summary Table

| Resource Type | Naming Source | Pattern | Example |
|---------------|---------------|---------|---------|
| Subscription | Custom | `sub-{workload}-{env}` | `sub-example-api-prod` |
| Resource Group (Identity) | Custom | `rg-identity-{workload}-{env}` | `rg-identity-example-api-prod` |
| Resource Group (Network) | Custom | `rg-network-{workload}-{env}` | `rg-network-example-api-prod` |
| Virtual Network | Naming Module | `vnet-{workload}-{env}` | `vnet-example-api-prod` |
| Subnet | Naming Module | `snet-{workload}-{env}-{name}` | `snet-example-api-prod-default` |
| User Assigned Identity (Plan) | Naming Module + Suffix | `id-{workload}-{env}-plan` | `id-example-api-prod-plan` |
| User Assigned Identity (Deploy) | Naming Module + Suffix | `id-{workload}-{env}-deploy` | `id-example-api-prod-deploy` |
| Budget | Custom | `budget-{workload}-{env}` | `budget-example-api-prod` |

## Validation Checklist

**Before implementing, review Azure naming module outputs:**
1. Visit https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs
2. Check if the resource type you need is available
3. If available: Use `module.naming[].{resource_type}.name`
4. If NOT available: Add abbreviation to `local.resource_abbreviations`

When implementing, verify:

- [ ] Reviewed Azure naming module outputs for all resource types needed
- [ ] Resource types in naming module use `module.naming[].{type}.name`
- [ ] Resource types NOT in naming module have abbreviation in `local.resource_abbreviations`
- [ ] Resource abbreviations are in locals (NOT exposed via variables/tfvars)
- [ ] Resource group names have purpose BEFORE workload: `{abbrev}-{purpose}-{workload}-{env}`
- [ ] Subscription names use abbreviation from locals: `${local.resource_abbreviations.subscription}-{workload}-{env}`
- [ ] Budget names use abbreviation from locals: `${local.resource_abbreviations.budget}-{workload}-{env}`
- [ ] Virtual network uses naming module: `module.naming[].virtual_network.name`
- [ ] UMI uses naming module + suffix: `${module.naming[].user_assigned_identity.name}-plan`
- [ ] Role assignments have `relative_scope = ""` for subscription scope
- [ ] No hardcoded abbreviations (all use `local.resource_abbreviations`)

## How to Identify Naming Module Gaps

### Step 1: List Required Resource Types
For LZ v3.0.0, we need:
- ✅ Subscriptions
- ✅ Resource Groups
- ✅ Virtual Networks
- ✅ Subnets
- ✅ User Assigned Identities
- ✅ Budgets

### Step 2: Check Azure Naming Module
Visit: https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

Look for outputs matching your resource types:
- `virtual_network` output? → ✅ Available, use naming module
- `subnet` output? → ✅ Available, use naming module
- `user_assigned_identity` output? → ✅ Available, use naming module
- `consumption_budget` output? → ❌ NOT available, add to locals
- `subscription` output? → ❌ NOT available, add to locals
- `resource_group` output? → ⚠️ Available but we need custom pattern with purpose prefix

### Step 3: Add Missing Abbreviations to Locals
```hcl
locals {
  resource_abbreviations = {
    # Add abbreviations for types NOT in naming module
    subscription   = "sub"     # No subscription output in naming module
    budget         = "budget"  # No consumption_budget output in naming module
    resource_group = "rg"      # Available but we need custom pattern
  }
}
```

### Step 4: Document Pattern
For each custom abbreviation, document:
- Why it's not using the naming module
- The pattern used (e.g., `{abbrev}-{workload}-{env}`)
- Example of resulting name

## Validation Checklist

When implementing, verify:

- [ ] Resource group names have purpose BEFORE workload: `rg-{purpose}-{workload}-{env}`
- [ ] Subscription names use custom `sub` prefix: `sub-{workload}-{env}`
- [ ] Budget names use custom `budget` prefix: `budget-{workload}-{env}`
- [ ] Virtual network uses naming module: `module.naming[].virtual_network.name`
- [ ] UMI uses naming module + suffix: `${module.naming[].user_assigned_identity.name}-plan`
- [ ] Role assignments have `relative_scope = ""` for subscription scope
- [ ] No attempt to use `module.naming[].consumption_budget` (doesn't exist)
- [ ] No attempt to use naming module for resource groups (custom pattern required)

## References

- Azure Naming Module: https://registry.terraform.io/modules/Azure/naming/azurerm/latest
- AVM Sub Vending Module: https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure/latest
