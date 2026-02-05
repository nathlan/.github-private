# Terraform Modules Registry

This file tracks all Terraform modules created for the organization.

## Active Modules

| Module Name | Repository URL | Latest Version | Status | Description |
|-------------|----------------|----------------|--------|-------------|
| terraform-azurerm-resource-group | [Link](https://github.com/nathlan/terraform-azurerm-resource-group) | v1.0.0 | ✅ Production Ready | Azure Resource Group wrapper with location validation |
| terraform-azurerm-storage-account | [Link](https://github.com/nathlan/terraform-azurerm-storage-account) | v0.1.0 | ✅ Production Ready | Storage Account with blob submodule and secure defaults |
| terraform-azurerm-landing-zone-vending | [Link](https://github.com/nathlan/terraform-azurerm-landing-zone-vending) | v1.0.0 → v1.0.1* | ✅ Production Ready | Subscription vending wrapper for Azure Landing Zones |
| terraform-azurerm-firewall | [Link](https://github.com/nathlan/terraform-azurerm-firewall) | v0.1.2 → v0.1.3* | ✅ Production Ready | Azure Firewall wrapper with Australian region validation |
| terraform-azurerm-firewall-policy | [Link](https://github.com/nathlan/terraform-azurerm-firewall-policy) | v0.1.0 → v0.2.0* | 🔧 Needs Update | Firewall Policy with rule collection groups (missing files) |

\* Pending PR merge

## Module Details

### terraform-azurerm-resource-group
- **AVM Source**: `Azure/avm-res-resources-resourcegroup/azurerm` ~> 0.2.2
- **Key Features**: Location validation (australiaeast/australiacentral), resource locks, role assignments
- **Submodules**: None

### terraform-azurerm-storage-account
- **AVM Source**: `Azure/avm-res-storage-storageaccount/azurerm` ~> 0.2
- **Key Features**: Generic parent + blob submodule with secure defaults
- **Submodules**: `modules/blob`

### terraform-azurerm-landing-zone-vending
- **AVM Source**: `Azure/avm-ptn-alz-sub-vending/azure` 0.1.0
- **Key Features**: Subscription alias, management group association, virtual network deployment
- **Submodules**: None
- **Pending Fix**: Add `required_version` to examples/basic/main.tf

### terraform-azurerm-firewall
- **AVM Source**: `Azure/avm-res-network-azurefirewall/azurerm` ~> 0.4.0
- **Key Features**: AZFW_VNet and AZFW_Hub SKU support, location validation (australiaeast/australiasoutheast)
- **Submodules**: None
- **Pending Fix**: Replace `!= []` with `length() > 0` in main.tf lines 16-17

### terraform-azurerm-firewall-policy
- **AVM Source**: `Azure/avm-res-network-firewallpolicy/azurerm` ~> 0.3
- **Key Features**: Firewall Policy with application/network/NAT rule collections
- **Submodules**: None (uses AVM submodule for rule collection groups)
- **Pending Fix**: Add missing files (variables.tf, versions.tf, .gitignore, examples/)

## Pending Actions

1. **terraform-azurerm-firewall-policy**: Create PR with missing files (variables.tf, versions.tf, examples/, .gitignore)
2. **terraform-azurerm-firewall**: Create PR fixing TFLint warnings (2 lines)
3. **terraform-azurerm-landing-zone-vending**: Create PR adding required_version to example (3 lines)

All fixes validated locally and ready for deployment.
