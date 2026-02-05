# Basic Example

This example demonstrates the basic usage of the Azure Blob Storage module with minimal configuration.

## Features Demonstrated

1. **Minimal Configuration**: Shows how to deploy a storage account with just 3 required parameters
2. **With Containers**: Shows how to add blob containers with metadata
3. **Secure Defaults**: All examples use the secure defaults provided by the module

## Usage

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Clean up
terraform destroy
```

## What Gets Created

### Basic Example (`blob_storage_basic`)

- Storage account with secure defaults:
  - Name: `stblobexample001`
  - Location: `australiaeast`
  - Replication: `ZRS` (Zone-Redundant Storage)
  - TLS: `1.2` minimum
  - Public access: Disabled
  - Shared key access: Disabled
  - Blob versioning: Enabled
  - Soft delete: Enabled (7 days)

### With Containers Example (`blob_storage_with_containers`)

- Storage account: `stblobexample002`
- Three blob containers:
  - `data` - General data storage
  - `logs` - Application logs with metadata
  - `backups` - System backups with retention metadata

## Outputs

The example provides outputs for:
- Storage account IDs
- Storage account names
- Blob endpoints
- Container information

## Required Values

Only 3 values are required to get started:

```hcl
module "blob_storage" {
  source = "../.."

  name                = "mystorageaccount"  # 3-24 chars, lowercase, numbers only
  resource_group_name = "my-resource-group" # Existing resource group
  location            = "australiaeast"     # australiaeast or australiasoutheast
}
```

## Security Notes

This example uses all the secure defaults:
- ✅ Public network access denied
- ✅ HTTPS-only traffic
- ✅ TLS 1.2 minimum
- ✅ Shared access keys disabled
- ✅ Blob versioning enabled
- ✅ Soft delete enabled
- ✅ Container soft delete enabled

No additional configuration needed for secure storage!

## Customization

To customize the configuration, you can override any of the default values. See the main [README](../../README.md) for more examples including:
- Custom network rules
- Public access (if needed)
- Custom TLS settings
- Custom blob properties

## Prerequisites

- Azure subscription
- Terraform >= 1.9.0
- Azure CLI authenticated or service principal configured
- Existing resource group (or remove the `azurerm_resource_group` resource and use an existing one)

## Notes

- Storage account names must be globally unique across Azure
- The examples use `stblobexample001` and `stblobexample002` which you should change to unique names
- Location is restricted to `australiaeast` or `australiasoutheast` as per module design
- The resource group is created for demonstration purposes; in production, use an existing resource group
