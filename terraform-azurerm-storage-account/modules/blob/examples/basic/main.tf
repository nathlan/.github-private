terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Example resource group (in real usage, this would already exist)
resource "azurerm_resource_group" "example" {
  name     = "rg-blob-storage-example"
  location = "australiaeast"

  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
  }
}

# Basic example - minimal configuration required
module "blob_storage_basic" {
  source = "../.."

  name                = "stblobexample001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
    Purpose     = "Basic Example"
  }
}

# Example with containers
module "blob_storage_with_containers" {
  source = "../.."

  name                = "stblobexample002"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

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
    backups = {
      name          = "backups"
      public_access = "None"
      metadata = {
        purpose   = "system-backups"
        retention = "30-days"
      }
    }
  }

  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
    Purpose     = "Containers Example"
  }
}

# Outputs for basic example
output "basic_storage_account_id" {
  description = "The ID of the basic storage account"
  value       = module.blob_storage_basic.storage_account_id
}

output "basic_storage_account_name" {
  description = "The name of the basic storage account"
  value       = module.blob_storage_basic.storage_account_name
}

output "basic_blob_endpoint" {
  description = "The primary blob endpoint"
  value       = module.blob_storage_basic.storage_account_primary_blob_endpoint
}

output "containers_storage_account_id" {
  description = "The ID of the storage account with containers"
  value       = module.blob_storage_with_containers.storage_account_id
}

output "containers_created" {
  description = "The containers that were created"
  value       = module.blob_storage_with_containers.containers
}
