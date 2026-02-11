# Landing Zone Module v3.0.0 - Naming Requirements

## Critical Naming Specifications

This document provides the **CORRECTED** naming requirements for the Landing Zone v3.0.0 module.

## Azure Naming Module vs Custom Prefixes

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
# Custom local value
local.subscription_names = {
  for lz_key, lz in var.landing_zones : lz_key => "sub-${lz.workload}-${lz.env}"
}

# Format: sub-{workload}-{env}
# Example: sub-example-api-prod
```

#### 2. Budgets
```hcl
# Custom naming (consumption_budget output does NOT exist in naming module)
name = "budget-${each.value.workload}-${each.value.env}"

# Format: budget-{workload}-{env}
# Example: budget-example-api-prod
```

**Note**: The Azure naming module does NOT have a `consumption_budget` output. Verify at:
https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

#### 3. Resource Groups ⚠️ CRITICAL CORRECTION
```hcl
# Custom naming with PURPOSE PREFIX
resource_groups = {
  rg_identity = {
    name = "rg-identity-${each.value.workload}-${each.value.env}"
  }
  rg_network = {
    name = "rg-network-${each.value.workload}-${each.value.env}"
  }
}

# Format: rg-{purpose}-{workload}-{env}
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
  # Subscriptions (custom prefix)
  subscription_names = {
    for lz_key, lz in var.landing_zones : lz_key => "sub-${lz.workload}-${lz.env}"
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

  # Subscription (custom naming)
  subscription_display_name = local.subscription_names[each.key]
  subscription_alias_name   = local.subscription_names[each.key]

  # Resource groups (custom naming with purpose prefix)
  resource_groups = {
    rg_identity = {
      name     = "rg-identity-${each.value.workload}-${each.value.env}"
      location = each.value.location
    }
    rg_network = {
      name     = "rg-network-${each.value.workload}-${each.value.env}"
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

  # Budgets (custom naming)
  budgets = {
    monthly = {
      name = "budget-${each.value.workload}-${each.value.env}"
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
