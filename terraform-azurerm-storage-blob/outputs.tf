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

output "storage_account_primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location."
  value       = module.storage_account.resource.primary_blob_host
}

output "storage_account_secondary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the secondary location."
  value       = module.storage_account.resource.secondary_blob_endpoint
}

output "storage_account_primary_connection_string" {
  description = "The connection string for the storage account in the primary location."
  value       = module.storage_account.resource.primary_connection_string
  sensitive   = true
}

output "storage_account_secondary_connection_string" {
  description = "The connection string for the storage account in the secondary location."
  value       = module.storage_account.resource.secondary_connection_string
  sensitive   = true
}

output "storage_account_primary_access_key" {
  description = "The primary access key for the storage account."
  value       = module.storage_account.resource.primary_access_key
  sensitive   = true
}

output "storage_account_secondary_access_key" {
  description = "The secondary access key for the storage account."
  value       = module.storage_account.resource.secondary_access_key
  sensitive   = true
}

output "containers" {
  description = "Map of created blob containers with their properties."
  value       = module.storage_account.containers
}

output "resource" {
  description = "The full storage account resource object."
  value       = module.storage_account.resource
  sensitive   = true
}
