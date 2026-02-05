# Terraform Modules Registry

This file tracks all Terraform modules created for the organization.

## Active Modules

| Module Name | Repository URL | Latest Version | Status | Description |
|-------------|----------------|----------------|--------|-------------|
| terraform-azurerm-resource-group | [Link](https://github.com/nathlan/terraform-azurerm-resource-group) | v1.0.0 | ✅ Production Ready | Azure Resource Group wrapper with location validation |
| terraform-azurerm-storage-account | [Link](https://github.com/nathlan/terraform-azurerm-storage-account) | v0.1.0 | ✅ Production Ready | Storage Account with blob submodule and secure defaults |
| terraform-azurerm-landing-zone-vending | [Link](https://github.com/nathlan/terraform-azurerm-landing-zone-vending) | v1.0.0 → v1.0.2* | 📝 PR Ready | Subscription vending wrapper for Azure Landing Zones |
| terraform-azurerm-firewall | [Link](https://github.com/nathlan/terraform-azurerm-firewall) | v0.1.2 → v0.1.4* | 📝 PR Ready | Azure Firewall wrapper with Australian region validation |
| terraform-azurerm-firewall-policy | [Link](https://github.com/nathlan/terraform-azurerm-firewall-policy) | v0.1.0 → v0.2.0* | 📝 PR Ready | Firewall Policy with rule collection groups |

\* Fix files prepared in `/tmp/pr-fixes/` - ready to create PRs

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
- **PR Ready**: Add `required_version` to examples/basic/main.tf (+4 lines)

### terraform-azurerm-firewall
- **AVM Source**: `Azure/avm-res-network-azurefirewall/azurerm` ~> 0.4.0
- **Key Features**: AZFW_VNet and AZFW_Hub SKU support, location validation (australiaeast/australiasoutheast)
- **Submodules**: None
- **PR Ready**: Replace `!= []` with `length() > 0` (2 lines modified)

### terraform-azurerm-firewall-policy
- **AVM Source**: `Azure/avm-res-network-firewallpolicy/azurerm` ~> 0.3
- **Key Features**: Firewall Policy with application/network/NAT rule collections
- **Submodules**: None (uses AVM submodule for rule collection groups)
- **PR Ready**: Add 5 missing files (variables.tf, versions.tf, .gitignore, examples/)

## PR Creation Instructions

All three module fixes are prepared in `/tmp/pr-fixes/` with complete instructions:

1. **landing-zone-vending** (v1.0.2): Add required_version - 4 lines added
2. **firewall** (v0.1.4): Replace != [] operators - 2 lines modified
3. **firewall-policy** (v0.2.0): Add missing files - 5 new files

See `/tmp/pr-fixes/APPLY_FIXES_INSTRUCTIONS.md` for detailed PR creation commands.
