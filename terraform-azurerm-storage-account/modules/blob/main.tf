# Azure Blob Storage Submodule
# This module provides opinionated defaults for blob storage use cases

module "storage_account" {
  source = "../.."

  # Required parameters
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Account configuration - optimized for blob storage
  account_kind             = "StorageV2"
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Security settings with secure defaults
  min_tls_version                  = var.min_tls_version
  public_network_access_enabled    = var.public_network_access_enabled
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  shared_access_key_enabled        = var.shared_access_key_enabled
  https_traffic_only_enabled       = var.https_traffic_only_enabled
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Network rules - secure by default
  network_rules = var.network_rules

  # Blob-specific properties with secure defaults
  blob_properties = {
    versioning_enabled            = lookup(var.blob_properties, "versioning_enabled", true)
    change_feed_enabled           = lookup(var.blob_properties, "change_feed_enabled", false)
    change_feed_retention_in_days = lookup(var.blob_properties, "change_feed_retention_in_days", null)
    default_service_version       = lookup(var.blob_properties, "default_service_version", null)
    last_access_time_enabled      = lookup(var.blob_properties, "last_access_time_enabled", true)

    container_delete_retention_policy = lookup(var.blob_properties, "container_delete_retention_policy", null) != null ? {
      days = lookup(lookup(var.blob_properties, "container_delete_retention_policy", {}), "days", 7)
    } : { days = 7 }

    delete_retention_policy = lookup(var.blob_properties, "delete_retention_policy", null) != null ? {
      days                     = lookup(lookup(var.blob_properties, "delete_retention_policy", {}), "days", 7)
      permanent_delete_enabled = lookup(lookup(var.blob_properties, "delete_retention_policy", {}), "permanent_delete_enabled", false)
      } : {
      days                     = 7
      permanent_delete_enabled = false
    }

    restore_policy = lookup(var.blob_properties, "restore_policy", null)
  }

  # Blob containers
  containers = {
    for key, container in var.containers : key => {
      name          = container.name
      public_access = coalesce(container.public_access, "None")
      metadata      = container.metadata
    }
  }

  # Tags
  tags = var.tags

  # Telemetry
  enable_telemetry = var.enable_telemetry
}
