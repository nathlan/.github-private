terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.19.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Create a resource group for the example
resource "azurerm_resource_group" "example" {
  name     = "rg-appservice-example"
  location = "East US"
}

# Deploy the App Service module
module "app_service" {
  source = "../.."

  name                = "mywebapp"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  # App Service Plan Configuration
  os_type                = "Linux"
  sku_name               = "P1v3"
  worker_count           = 1
  zone_balancing_enabled = false

  # Web App Configuration
  always_on           = true
  https_only          = true
  http2_enabled       = true
  minimum_tls_version = "1.3"
  ftps_state          = "FtpsOnly"

  # Application Stack - Node.js example
  application_stack = {
    node_version = "20-lts"
  }

  # App Settings
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~20"
    "ENVIRONMENT"                  = "Development"
  }

  # Enable System-Assigned Managed Identity
  managed_identities = {
    system_assigned = true
  }

  # Tags
  tags = {
    Environment = "Development"
    Project     = "Example"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "app_service_url" {
  description = "The URL of the deployed App Service"
  value       = module.app_service.app_service_default_site_hostname
}

output "app_service_name" {
  description = "The name of the App Service"
  value       = module.app_service.app_service_name
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan"
  value       = module.app_service.app_service_plan_name
}
