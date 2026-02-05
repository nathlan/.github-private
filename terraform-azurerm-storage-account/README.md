# Azure Storage Account Terraform Module

Terraform module to create an Azure Storage Account with support for all storage types (Blob, File, Table, Queue).

This module wraps the [Azure Verified Module (AVM) for Storage Account](https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest) providing a flexible foundation for various storage scenarios.

## Features

- 🔧 Generic storage account module supporting all Azure storage types
- 🔒 Configurable security settings with sensible defaults
- 📦 Support for Blob, File, Table, and Queue storage
- 🎯 Opinionated submodules for specific use cases
- 🛡️ All settings are configurable

## Usage

### Basic Storage Account

```hcl
module "storage_account" {
  source  = "github.com/nathlan/terraform-azurerm-storage-account"
  version = "1.0.0"

  name                = "mystorageacct001"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"
}
```

### Using Submodules

For specific storage types with opinionated defaults, use submodules:

#### Blob Storage (Opinionated)

```hcl
module "blob_storage" {
  source  = "github.com/nathlan/terraform-azurerm-storage-account//modules/blob"
  version = "1.0.0"

  name                = "myblobstorage001"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"
}
```

See [modules/blob/README.md](./modules/blob/README.md) for blob-specific features.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [blob](./modules/blob/) | Opinionated blob storage with secure defaults and region restrictions |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account) | Azure/avm-res-storage-storageaccount/azurerm | ~> 0.6.7 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the storage account. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the storage account. Must be between 3 and 24 characters and globally unique. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the storage account. | `string` | n/a | yes |
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. | `string` | `"StorageV2"` | no |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. | `string` | `"ZRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Defines the Tier to use for this storage account. Valid options are Standard and Premium. | `string` | `"Standard"` | no |
| <a name="input_allow_nested_items_to_be_public"></a> [allow\_nested\_items\_to\_be\_public](#input\_allow\_nested\_items\_to\_be\_public) | Allow or disallow nested items within this Account to opt into being public. Defaults to false for security. | `bool` | `false` | no |
| <a name="input_blob_properties"></a> [blob\_properties](#input\_blob\_properties) | Blob service properties for the storage account. | `object({...})` | `null` | no |
| <a name="input_containers"></a> [containers](#input\_containers) | Map of blob containers to create. | `map(object({...}))` | `{}` | no |
| <a name="input_cross_tenant_replication_enabled"></a> [cross\_tenant\_replication\_enabled](#input\_cross\_tenant\_replication\_enabled) | Should cross Tenant replication be enabled? Defaults to false for security. | `bool` | `false` | no |
| <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry) | Controls whether telemetry is enabled for the AVM module. Defaults to true. | `bool` | `true` | no |
| <a name="input_https_traffic_only_enabled"></a> [https\_traffic\_only\_enabled](#input\_https\_traffic\_only\_enabled) | Boolean flag which forces HTTPS if enabled. Defaults to true for security. | `bool` | `true` | no |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | The minimum supported TLS version for the storage account. | `string` | `"TLS1_2"` | no |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | Network rules for the storage account. Defaults to denying all traffic except Azure Services. | `object({...})` | `{}` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is allowed for this storage account. Defaults to false for security. | `bool` | `false` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | Map of storage queues to create. | `map(object({...}))` | `{}` | no |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. Defaults to false for enhanced security. | `bool` | `false` | no |
| <a name="input_shares"></a> [shares](#input\_shares) | Map of file shares to create. | `map(object({...}))` | `{}` | no |
| <a name="input_tables"></a> [tables](#input\_tables) | Map of storage tables to create. | `map(object({...}))` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_containers"></a> [containers](#output\_containers) | Map of created blob containers with their properties. |
| <a name="output_queues"></a> [queues](#output\_queues) | Map of created storage queues with their properties. |
| <a name="output_resource"></a> [resource](#output\_resource) | The full storage account resource object. |
| <a name="output_shares"></a> [shares](#output\_shares) | Map of created file shares with their properties. |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | The ID of the storage account. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the storage account. |
| <a name="output_storage_account_primary_access_key"></a> [storage\_account\_primary\_access\_key](#output\_storage\_account\_primary\_access\_key) | The primary access key for the storage account. |
| <a name="output_storage_account_primary_blob_endpoint"></a> [storage\_account\_primary\_blob\_endpoint](#output\_storage\_account\_primary\_blob\_endpoint) | The endpoint URL for blob storage in the primary location. |
| <a name="output_storage_account_primary_connection_string"></a> [storage\_account\_primary\_connection\_string](#output\_storage\_account\_primary\_connection\_string) | The connection string for the storage account in the primary location. |
| <a name="output_storage_account_primary_location"></a> [storage\_account\_primary\_location](#output\_storage\_account\_primary\_location) | The primary location of the storage account. |
| <a name="output_tables"></a> [tables](#output\_tables) | Map of created storage tables with their properties. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

See [LICENSE](LICENSE) for license information.
