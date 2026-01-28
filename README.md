# Azure App Service Terraform Module

A comprehensive Terraform module for deploying Azure App Service (Web App) with App Service Plan using Azure Verified Modules (AVM).

## Features

- ✅ Deploys App Service Plan and App Service using Azure Verified Modules
- ✅ Supports both Linux and Windows operating systems
- ✅ Configurable SKU and worker count for scaling
- ✅ Multiple runtime stacks (.NET, Node.js, Python, Java, PHP, Go, Ruby, Docker)
- ✅ HTTPS enforcement and TLS version control
- ✅ Managed Identity support (System-assigned and User-assigned)
- ✅ VNet integration support
- ✅ IP restrictions and access control
- ✅ Health check configuration
- ✅ Custom app settings and connection strings
- ✅ Zone redundancy for high availability
- ✅ Comprehensive tagging support

## Azure Verified Modules Used

- [Azure/avm-res-web-serverfarm](https://registry.terraform.io/modules/Azure/avm-res-web-serverfarm/azurerm) v1.0
- [Azure/avm-res-web-site](https://registry.terraform.io/modules/Azure/avm-res-web-site/azurerm) v0.19

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | >= 4.19.0, < 5.0.0 |
| random | >= 3.5.0, < 4.0.0 |

## Usage

```hcl
module "app_service" {
  source = "path/to/module"

  name                = "mywebapp"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  os_type      = "Linux"
  sku_name     = "P1v3"
  worker_count = 1

  always_on           = true
  https_only          = true
  minimum_tls_version = "1.3"

  application_stack = {
    node_version = "20-lts"
  }

  app_settings = {
    "ENVIRONMENT" = "Production"
  }

  tags = {
    Environment = "Production"
  }
}
```

## Examples

See the [examples](./examples/) directory for complete examples.

## License

MIT License
