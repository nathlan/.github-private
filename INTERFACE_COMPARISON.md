# Quick Reference: Before vs After Interface

## Single Landing Zone Example

### BEFORE (feature/add-ip-address-automation)
```hcl
module "landing_zone" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending"

  location = "australiaeast"

  # Manual flags
  subscription_alias_enabled = true
  subscription_management_group_association_enabled = true
  resource_group_creation_enabled = true
  virtual_network_enabled = true
  umi_enabled = true
  budget_enabled = true

  # Subscription config
  subscription_billing_scope = var.billing_scope
  subscription_display_name = "sub-example-api-prod"
  subscription_alias_name = "sub-example-api-prod"
  subscription_workload = "Production"
  subscription_management_group_id = var.mgmt_group_id
  subscription_tags = {
    env = "prod"
    workload = "example-api"
    team = "app-engineering"
    cost_centre = "IT-DEV-002"
  }

  # Manual resource groups
  resource_groups = {
    rg_identity = {
      name = "rg-example-api-prod-identity"
      location = "australiaeast"
      tags = {}
    }
    rg_network = {
      name = "rg-example-api-prod-network"
      location = "australiaeast"
      tags = {}
    }
  }

  # IP automation
  ip_address_automation_enabled = true
  ip_address_automation_address_space = "10.100.0.0/16"
  ip_address_automation_vnet_prefix_sizes = {
    spoke = 24
  }

  # Manual virtual networks
  virtual_networks = {
    spoke = {
      name = "vnet-example-api-prod"
      resource_group_key = "rg_network"
      location = "australiaeast"
      hub_network_resource_id = var.hub_network_resource_id
      hub_peering_enabled = true
      # address_space auto-calculated
    }
  }

  # Manual UMI
  user_managed_identities = {
    umi_main = {
      name = "id-example-api-prod"
      resource_group_key = "rg_identity"
      location = "australiaeast"
      tags = {}

      federated_credentials_github = {
        github_oidc = {
          name = "oidc-gh-example-api-prod"
          organization = "nathlan"
          repository = "example-api-prod"
          entity = "pull_request"
        }
      }
    }
  }

  # Manual budget
  budgets = {
    main = {
      name = "budget-example-api-prod"
      amount = 500
      time_grain = "Monthly"
      time_period_start = "2024-01-01T00:00:00Z"
      time_period_end = "2025-01-01T00:00:00Z"

      notifications = {
        threshold_notification = {
          enabled = true
          operator = "GreaterThanOrEqualTo"
          threshold = 80
          threshold_type = "Actual"
          contact_emails = ["dev-team@example.com"]
          locale = "en-us"
        }
      }
    }
  }
}
```
**Total: ~95 lines**

---

### AFTER (feature/naming-and-smart-defaults)
```hcl
module "landing_zones" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending"

  # Common configuration
  subscription_billing_scope = var.billing_scope
  hub_network_resource_id = var.hub_network_resource_id
  subscription_management_group_id = var.mgmt_group_id
  github_organization = "nathlan"
  base_address_space = "10.100.0.0/16"

  tags = {
    managed_by = "terraform"
  }

  landing_zones = {
    example-api-prod = {
      workload = "example-api"
      env = "prod"
      team = "app-engineering"
      location = "australiaeast"

      subscription_tags = {
        cost_centre = "IT-DEV-002"
      }

      virtual_networks = {
        spoke = {
          address_space_required = "/24"
        }
      }

      budgets = {
        amount = 500
        threshold = 80
        contact_emails = ["dev-team@example.com"]
      }

      federated_credentials_github = {
        repository = "example-api-prod"
      }
    }
  }
}
```
**Total: ~30 lines (68% reduction)**

---

## Multiple Landing Zones

### BEFORE
You would need to create multiple module blocks, each ~95 lines.

### AFTER
```hcl
module "landing_zones" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending"

  subscription_billing_scope = var.billing_scope
  hub_network_resource_id = var.hub_network_resource_id
  subscription_management_group_id = var.mgmt_group_id
  github_organization = "nathlan"
  base_address_space = "10.100.0.0/16"

  tags = { managed_by = "terraform" }

  landing_zones = {
    # Production API
    example-api-prod = {
      workload = "example-api"
      env = "prod"
      team = "app-engineering"
      location = "australiaeast"

      virtual_networks = {
        spoke = { address_space_required = "/24" }
      }

      budgets = {
        amount = 500
        threshold = 80
        contact_emails = ["dev-team@example.com"]
      }

      federated_credentials_github = {
        repository = "example-api-prod"
      }
    }

    # Dev Web App
    webapp-dev = {
      workload = "webapp"
      env = "dev"
      team = "web-team"
      location = "australiaeast"
      subscription_devtest_enabled = true  # DevTest pricing

      virtual_networks = {
        spoke = { address_space_required = "/26" }
      }

      budgets = {
        amount = 100
        threshold = 90
        contact_emails = ["web-team@example.com"]
      }

      federated_credentials_github = {
        repository = "webapp-infrastructure"
      }
    }
  }
}
```

**Total: ~50 lines for 2 landing zones (vs ~190 lines before)**

---

## What Gets Auto-Generated

For landing zone `example-api-prod`:

| Resource | Name |
|----------|------|
| Subscription | `sub-example-api-prod` |
| Identity RG | `rg-example-api-prod-identity` |
| Network RG | `rg-example-api-prod-network` |
| Virtual Network | `vnet-example-api-prod` (from naming module) |
| User-Managed Identity | `id-example-api-prod` (from naming module) |
| Budget | `budget-example-api-prod` |
| GitHub OIDC Credential | `oidc-gh-example-api-prod` |

## What Gets Auto-Enabled

Based on configuration presence:
- `subscription_alias_enabled = true` (always)
- `subscription_management_group_association_enabled = true` (always)
- `resource_group_creation_enabled = true` (always)
- `virtual_network_enabled = true` (when virtual_networks configured)
- `umi_enabled = true` (when federated_credentials_github configured)
- `budget_enabled = true` (when budgets configured)

## What Gets Auto-Calculated

- **Address Spaces**: From `base_address_space` + per-VNet prefix size
- **Budget Time Periods**: Current month + 1 year from timestamp()
- **Budget Notifications**: Standard structure with user-provided threshold
- **Tags**: Merge of common + auto (env/workload/team) + user subscription_tags
- **Subscription Workload**: "Production" or "DevTest" based on boolean flag

## Migration Path

1. **Update module source**: Keep same or update to new branch
2. **Restructure variables**: Move to `landing_zones` map
3. **Remove manual names**: Let module generate from workload/env
4. **Simplify budgets**: Just amount/threshold/emails
5. **Simplify GitHub OIDC**: Just repository name
6. **Remove boolean flags**: Auto-enabled based on config
7. **Update IP automation**: Use common `base_address_space`

## Validation

Both versions pass all validation:
- ✅ terraform fmt
- ✅ terraform validate
- ✅ tflint
- ✅ checkov
- ✅ terraform-docs
