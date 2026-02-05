output "storage_account_id" {
  description = "The ID of the storage account."
  value       = module.storage_account.resource_id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_primary_location" {
  description = "The primary location of the storage account."
  value       = module.storage_account.resource.location
}

output "storage_account_primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location."
  value       = module.storage_account.resource.primary_blob_endpoint
}

output "storage_account_primary_connection_string" {
  description = "The connection string for the storage account in the primary location."
  value       = module.storage_account.resource.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_access_key" {
  description = "The primary access key for the storage account."
  value       = module.storage_account.resource.primary_access_key
  sensitive   = true
}

output "containers" {
  description = "Map of created blob containers with their properties."
  value       = module.storage_account.containers
}

output "queues" {
  description = "Map of created storage queues with their properties."
  value       = module.storage_account.queues
}

output "tables" {
  description = "Map of created storage tables with their properties."
  value       = module.storage_account.tables
}

output "shares" {
  description = "Map of created file shares with their properties."
  value       = module.storage_account.shares
}

output "resource" {
  description = "The full storage account resource object."
  value       = module.storage_account.resource
  sensitive   = true
}
