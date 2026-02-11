# Resource Abbreviations Pattern - Quick Reference

## Purpose

Handle resource type abbreviations for types NOT in the Azure naming module in a way that:
- ✅ Platform team can update centrally
- ✅ Maintains consistency across all landing zones
- ❌ NOT exposed to end users via tfvars
- ✅ Easy to maintain if standards change

## The Pattern

### Step 1: Define Abbreviations in Locals

```hcl
# In main.tf (internal to module, NOT exposed to users)
locals {
  # Resource abbreviations for types NOT in Azure naming module
  # Platform team updates these - users cannot override
  resource_abbreviations = {
    subscription   = "sub"
    budget         = "budget"
    resource_group = "rg"
    # Add more as needed after reviewing naming module
  }
}
```

### Step 2: Use Abbreviations in Naming Patterns

```hcl
# Subscriptions
locals {
  subscription_names = {
    for lz_key, lz in var.landing_zones : 
      lz_key => "${local.resource_abbreviations.subscription}-${lz.workload}-${lz.env}"
  }
}
# Result: sub-example-api-prod

# Resource Groups
resource_groups = {
  rg_identity = {
    name = "${local.resource_abbreviations.resource_group}-identity-${each.value.workload}-${each.value.env}"
  }
}
# Result: rg-identity-example-api-prod

# Budgets
budgets = {
  monthly = {
    name = "${local.resource_abbreviations.budget}-${each.value.workload}-${each.value.env}"
  }
}
# Result: budget-example-api-prod
```

## Why This Pattern?

### ❌ Without Pattern (Hardcoded)
```hcl
# Bad: Hardcoded abbreviations
name = "sub-${workload}-${env}"
name = "budget-${workload}-${env}"
name = "rg-identity-${workload}-${env}"

# Problems:
# - Difficult to change if standards evolve
# - Inconsistent if different developers use different abbreviations
# - No single source of truth
```

### ✅ With Pattern (Locals)
```hcl
# Good: Centralized abbreviations
locals {
  resource_abbreviations = {
    subscription = "sub"
    budget       = "budget"
  }
}

name = "${local.resource_abbreviations.subscription}-${workload}-${env}"
name = "${local.resource_abbreviations.budget}-${workload}-${env}"

# Benefits:
# - Single source of truth
# - Easy to update centrally
# - Consistent across entire module
# - Platform team controls, users don't see it
```

## When to Use This Pattern

### Check Azure Naming Module First

Always review available outputs:
https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs

| Resource Type | In Naming Module? | Action |
|---------------|-------------------|---------|
| Virtual Network | ✅ Yes (`virtual_network`) | Use naming module |
| Subnet | ✅ Yes (`subnet`) | Use naming module |
| User Assigned Identity | ✅ Yes (`user_assigned_identity`) | Use naming module |
| Subscription | ❌ No | Add to `resource_abbreviations` |
| Budget | ❌ No (`consumption_budget` doesn't exist) | Add to `resource_abbreviations` |
| Resource Group | ⚠️ Yes, but need custom pattern | Add to `resource_abbreviations` |

### Decision Tree

```
Need to name a resource?
│
├─→ Is it in Azure naming module outputs?
│   │
│   ├─→ YES: Use module.naming[].{type}.name
│   │
│   └─→ NO: Add to local.resource_abbreviations
│
└─→ Does it need special pattern (e.g., purpose prefix)?
    │
    └─→ YES: Add to local.resource_abbreviations
```

## Complete Example

```hcl
# ========================================
# Resource Abbreviations (Internal)
# ========================================
locals {
  resource_abbreviations = {
    subscription   = "sub"
    budget         = "budget"
    resource_group = "rg"
  }
}

# ========================================
# Azure Naming Module
# ========================================
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.3"
  
  for_each = var.landing_zones
  suffix   = [each.value.workload, each.value.env]
}

# ========================================
# Usage Examples
# ========================================

# Use abbreviations for custom types
locals {
  subscription_names = {
    for lz_key, lz in var.landing_zones : 
      lz_key => "${local.resource_abbreviations.subscription}-${lz.workload}-${lz.env}"
  }
}

resource_groups = {
  rg_identity = {
    name = "${local.resource_abbreviations.resource_group}-identity-${each.value.workload}-${each.value.env}"
  }
}

budgets = {
  monthly = {
    name = "${local.resource_abbreviations.budget}-${each.value.workload}-${each.value.env}"
  }
}

# Use naming module for supported types
virtual_networks = {
  spoke = {
    name = module.naming[each.key].virtual_network.name
    # Result: vnet-example-api-prod
  }
}

user_managed_identities = {
  plan = {
    name = "${module.naming[each.key].user_assigned_identity.name}-plan"
    # Result: id-example-api-prod-plan
  }
}
```

## How to Update Abbreviations

### Scenario: Organization changes standards

**Old Standard**: Use "sub" for subscriptions  
**New Standard**: Use "subscription" for subscriptions

### Update Process (Easy!)

```hcl
# Just update the locals block
locals {
  resource_abbreviations = {
    subscription   = "subscription"  # Changed from "sub"
    budget         = "budget"
    resource_group = "rg"
  }
}

# All references automatically update:
# Old: sub-example-api-prod
# New: subscription-example-api-prod
```

**No changes needed** in:
- Variable files
- User configurations
- Module calls
- Examples

**Only change** the `resource_abbreviations` local in `main.tf`!

## Key Principles

1. **Always Check Naming Module First**: Don't reinvent what exists
2. **Use Locals, Not Variables**: Keep abbreviations internal
3. **Single Source of Truth**: Define once, use everywhere
4. **Platform Team Owns It**: Users don't see or modify abbreviations
5. **Document Decisions**: Note why each abbreviation is custom

## References

- Azure Naming Module: https://registry.terraform.io/modules/Azure/naming/azurerm/latest?tab=outputs
- LZ v3.0.0 Naming Requirements: `LZ_V3_NAMING_REQUIREMENTS.md`
- Agent Deployment Guide: `LZ_V3_AGENT_DEPLOYMENT_GUIDE.md`

---

**Last Updated**: 2026-02-11  
**Pattern**: Resource Abbreviations in Locals (NOT Variables)
