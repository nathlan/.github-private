# Example: Clean Landing Zone Vending with Smart Defaults

This example demonstrates the simplified interface for creating landing zones with auto-generated names and smart defaults.

## Usage

```hcl
module "landing_zones" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending"

  # Common variables
  subscription_billing_scope       = var.billing_scope
  hub_network_resource_id          = var.hub_network_resource_id
  subscription_management_group_id = var.mgmt_group_id
  github_organization              = "nathlan"
  base_address_space               = "10.100.0.0/16"

  tags = {
    managed_by = "terraform"
  }

  landing_zones = {
    example-api-prod = {
      workload = "example-api"
      env      = "prod"
      team     = "app-engineering"
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
        amount         = 500
        threshold      = 80
        contact_emails = ["dev-team@example.com"]
      }

      federated_credentials_github = {
        repository = "example-api-prod"
      }
    }
  }
}
```

## What Gets Created

For each landing zone, the module automatically creates:

1. **Subscription**: `sub-example-api-prod`
2. **Resource Groups**:
   - `rg-example-api-prod-identity`
   - `rg-example-api-prod-network`
3. **Virtual Network**: Auto-generated name from naming module with /24 address space
4. **User-Managed Identity**: Auto-generated name with GitHub OIDC federation
5. **Budget**: `budget-example-api-prod` with monthly alerts
6. **Tags**: Automatically includes `env`, `workload`, `team`, plus any custom tags

## Benefits

- **No manual naming**: All resources use Azure naming module conventions
- **No verbose flags**: Smart defaults for `subscription_alias_enabled`, `resource_group_creation_enabled`, etc.
- **Clean interface**: Users focus on business requirements, not infrastructure boilerplate
- **Type safety**: Strong validation ensures correct configurations
- **Automatic IP addressing**: Optional base address space with efficient allocation

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_landing_zones"></a> [landing\_zones](#module\_landing\_zones) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_landing_zone_subscription_ids"></a> [landing\_zone\_subscription\_ids](#output\_landing\_zone\_subscription\_ids) | Map of landing zone keys to subscription IDs |
| <a name="output_landing_zone_umi_client_ids"></a> [landing\_zone\_umi\_client\_ids](#output\_landing\_zone\_umi\_client\_ids) | Map of landing zone keys to UMI client IDs for GitHub Actions |
<!-- END_TF_DOCS -->
