# Terraform Modules Registry

This file tracks all Terraform modules created for the organization.

## Active Modules

| Module Name | Repository URL | Latest Version | Status | Description |
|-------------|----------------|----------------|--------|-------------|
| terraform-azurerm-resource-group | [Link](https://github.com/nathlan/terraform-azurerm-resource-group) | v1.0.0 → v2.0.0 | 🔄 PR Open | Azure Resource Group with naming integration |
| terraform-azurerm-storage-account | [Link](https://github.com/nathlan/terraform-azurerm-storage-account) | v0.1.0 → v0.2.0 | 🔄 PR Open | Storage Account with naming integration |
| terraform-azurerm-landing-zone-vending | [Link](https://github.com/nathlan/terraform-azurerm-landing-zone-vending) | v1.0.0 → v1.0.2 | 🔄 PR Open | Subscription vending wrapper for Azure Landing Zones |
| terraform-azurerm-firewall | [Link](https://github.com/nathlan/terraform-azurerm-firewall) | v0.1.2 → v0.1.4 | 🔄 PR Open | Azure Firewall wrapper with Australian region validation |
| terraform-azurerm-firewall-policy | [Link](https://github.com/nathlan/terraform-azurerm-firewall-policy) | v0.1.0 → v0.2.0 | 🔄 PR Open | Firewall Policy with rule collection groups |

## Module Details

### terraform-azurerm-resource-group
- **AVM Source**: `Azure/avm-res-resources-resourcegroup/azurerm` ~> 0.2.2
- **Naming Module**: `Azure/naming/azurerm` ~> 0.4.3
- **Key Features**: Location validation, resource locks, role assignments, integrated naming, automatic tagging
- **Submodules**: None
- **PR**: [#3](https://github.com/nathlan/terraform-azurerm-resource-group/pull/3) - Integrate Azure naming module with automatic tagging

### terraform-azurerm-storage-account
- **AVM Source**: `Azure/avm-res-storage-storageaccount/azurerm` ~> 0.6.7
- **Naming Module**: `Azure/naming/azurerm` ~> 0.4.3
- **Key Features**: Generic parent + blob submodule, integrated naming convention, automatic tagging
- **Submodules**: `modules/blob`
- **PR**: [#3](https://github.com/nathlan/terraform-azurerm-storage-account/pull/3) - Integrate Azure naming module with automatic tagging

### terraform-azurerm-landing-zone-vending
- **AVM Source**: `Azure/avm-ptn-alz-sub-vending/azure` 0.1.0
- **Key Features**: Subscription alias, management group association, virtual network deployment
- **Submodules**: None
- **PR**: [#3](https://github.com/nathlan/terraform-azurerm-landing-zone-vending/pull/3) - Add terraform version constraint

### terraform-azurerm-firewall
- **AVM Source**: `Azure/avm-res-network-azurefirewall/azurerm` ~> 0.4.0
- **Key Features**: AZFW_VNet and AZFW_Hub SKU support, location validation (australiaeast/australiasoutheast)
- **Submodules**: None
- **PR**: [#4](https://github.com/nathlan/terraform-azurerm-firewall/pull/4) - Replace list comparison operators

### terraform-azurerm-firewall-policy
- **AVM Source**: `Azure/avm-res-network-firewallpolicy/azurerm` ~> 0.3
- **Key Features**: Firewall Policy with application/network/NAT rule collections
- **Submodules**: None (uses AVM submodule for rule collection groups)
- **PR**: [#2](https://github.com/nathlan/terraform-azurerm-firewall-policy/pull/2) - Add missing module files
