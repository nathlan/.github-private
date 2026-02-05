# Azure Blob Storage Terraform Module

This module creates an Azure Storage Account optimized for Blob Storage with secure defaults. It wraps the [Azure Verified Module (AVM) for Storage Account](https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest) with opinionated security settings and simplified configuration.

## Features

- ✅ **Secure by Default**: Implements security best practices out of the box
- 🔒 **Private by Default**: Network access denied by default
- 📦 **Blob-Focused**: Optimized specifically for blob storage use cases
- 🌏 **Region-Restricted**: Only allows australiaeast and australiasoutheast regions
- 🛡️ **Security Features Enabled**:
  - TLS 1.2 minimum (configurable)
  - HTTPS-only traffic
  - Shared access key disabled by default
  - Public access blocked by default
  - Blob versioning enabled
  - Soft delete with 7-day retention
  - Container soft delete with 7-day retention

## Usage

### Basic Example (Minimal Configuration)

```hcl
module "blob_storage" {
  source = "./terraform-azurerm-storage-blob"

  name                = "mystorageacct001"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### With Blob Containers

```hcl
module "blob_storage" {
  source = "./terraform-azurerm-storage-blob"

  name                = "mystorageacct001"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"

  containers = {
    data = {
      name          = "data"
      public_access = "None"
    }
    logs = {
      name          = "logs"
      public_access = "None"
      metadata = {
        purpose = "application-logs"
      }
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### With Custom Network Rules

```hcl
module "blob_storage" {
  source = "./terraform-azurerm-storage-blob"

  name                = "mystorageacct001"
  resource_group_name = "my-resource-group"
  location            = "australiasoutheast"

  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = ["/subscriptions/.../subnets/subnet1"]
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Allowing Public Access (If Needed)

```hcl
module "blob_storage" {
  source = "./terraform-azurerm-storage-blob"

  name                = "publicstorageacct"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"

  # Override secure defaults for public access
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true

  containers = {
    public_content = {
      name          = "public-content"
      public_access = "Blob"  # Allow blob-level public access
    }
  }

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

### Weakening TLS (Not Recommended)

```hcl
module "blob_storage" {
  source = "./terraform-azurerm-storage-blob"

  name                = "legacystorageacct"
  resource_group_name = "my-resource-group"
  location            = "australiaeast"

  # Override TLS minimum version (use with caution)
  min_tls_version = "TLS1_0"

  tags = {
    Environment = "Legacy-System"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| azurerm | >= 4.0.0, < 5.0.0 |
| random | >= 3.6.0 |

## Providers

This module uses the Azure Verified Module (AVM) for Storage Account internally.

## Resources Created

- Azure Storage Account (via AVM)
- Blob Containers (optional)
- Network Rules (optional)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the storage account (3-24 chars, lowercase letters and numbers only) | `string` | n/a | yes |
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| location | Azure region (australiaeast or australiasoutheast only) | `string` | n/a | yes |
| account_tier | Storage account tier (Standard or Premium) | `string` | `"Standard"` | no |
| account_replication_type | Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS) | `string` | `"ZRS"` | no |
| containers | Map of blob containers to create | `map(object)` | `{}` | no |
| blob_properties | Blob service properties | `object` | `{}` (secure defaults applied) | no |
| min_tls_version | Minimum TLS version | `string` | `"TLS1_2"` | no |
| public_network_access_enabled | Allow public network access | `bool` | `false` | no |
| allow_nested_items_to_be_public | Allow containers/blobs to be public | `bool` | `false` | no |
| shared_access_key_enabled | Enable shared access key authentication | `bool` | `false` | no |
| https_traffic_only_enabled | Force HTTPS traffic only | `bool` | `true` | no |
| cross_tenant_replication_enabled | Enable cross-tenant replication | `bool` | `false` | no |
| network_rules | Network access rules | `object` | `{ default_action = "Deny" }` | no |
| tags | Tags to assign to resources | `map(string)` | `{}` | no |
| enable_telemetry | Enable AVM telemetry | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_id | The ID of the storage account |
| storage_account_name | The name of the storage account |
| storage_account_primary_location | The primary location of the storage account |
| storage_account_primary_blob_endpoint | The primary blob endpoint URL |
| storage_account_primary_blob_host | The primary blob host |
| storage_account_secondary_blob_endpoint | The secondary blob endpoint URL |
| storage_account_primary_connection_string | Primary connection string (sensitive) |
| storage_account_secondary_connection_string | Secondary connection string (sensitive) |
| storage_account_primary_access_key | Primary access key (sensitive) |
| storage_account_secondary_access_key | Secondary access key (sensitive) |
| containers | Map of created containers |
| resource | Full storage account resource object (sensitive) |

## Security Considerations

### Default Security Posture

This module implements the following security best practices by default:

1. **Network Isolation**: Public network access is denied by default
2. **Authentication**: Shared access keys are disabled, promoting Azure AD authentication
3. **Encryption**: HTTPS-only traffic is enforced
4. **TLS**: Minimum TLS version is 1.2
5. **Data Protection**: 
   - Blob versioning enabled
   - Soft delete for blobs (7 days)
   - Soft delete for containers (7 days)
6. **Access Control**: Nested items cannot be made public by default

### Overriding Security Defaults

While this module provides secure defaults, you can override them when necessary:

```hcl
# Example: Legacy system requiring older TLS
min_tls_version = "TLS1_0"  # Use with caution

# Example: Public-facing static website
public_network_access_enabled   = true
allow_nested_items_to_be_public = true

# Example: Applications using connection strings
shared_access_key_enabled = true
```

**⚠️ Warning**: Weakening security settings should be done with careful consideration and proper security review.

## Azure Verified Module (AVM) Integration

This module consumes the official Azure Verified Module for Storage Account:
- **Module**: `Azure/avm-res-storage-storageaccount/azurerm`
- **Version**: `~> 0.6.7`
- **Registry**: [Terraform Registry](https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest)

The AVM provides:
- Production-ready, tested configurations
- Microsoft's recommended practices
- Regular security updates
- Comprehensive feature coverage

## Examples

See the [examples/basic](./examples/basic) directory for a complete working example.

## Contributing

When contributing to this module:

1. Ensure all changes pass validation:
   ```bash
   terraform fmt -recursive
   terraform validate
   tflint --recursive
   checkov -d . --compact --quiet
   ```

2. Update documentation for any new variables or outputs
3. Add examples for new features
4. Test changes with the example configuration

## License

See [LICENSE](../LICENSE) for license information.

## Support

For issues or questions:
1. Check existing examples and documentation
2. Review the [AVM Storage Account module documentation](https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest)
3. Open an issue with detailed information about your use case
