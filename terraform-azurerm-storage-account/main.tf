# Azure Storage Account Module using Azure Verified Module (AVM)
# This is a generic storage account module that supports all storage types

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6.7"

  # Required parameters
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Account configuration
  account_kind             = var.account_kind
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Security settings
  min_tls_version                  = var.min_tls_version
  public_network_access_enabled    = var.public_network_access_enabled
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  shared_access_key_enabled        = var.shared_access_key_enabled
  https_traffic_only_enabled       = var.https_traffic_only_enabled
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Network rules
  network_rules = var.network_rules.default_action != null || length(var.network_rules.ip_rules) > 0 || length(var.network_rules.virtual_network_subnet_ids) > 0 || length(var.network_rules.bypass) > 0 ? {
    default_action             = coalesce(var.network_rules.default_action, "Deny")
    bypass                     = var.network_rules.bypass != null ? var.network_rules.bypass : ["AzureServices"]
    ip_rules                   = var.network_rules.ip_rules != null ? var.network_rules.ip_rules : []
    virtual_network_subnet_ids = var.network_rules.virtual_network_subnet_ids != null ? var.network_rules.virtual_network_subnet_ids : []
  } : null

  # Blob properties (if provided)
  blob_properties = var.blob_properties

  # Child resources
  containers = var.containers
  queues     = var.queues
  tables     = var.tables
  shares     = var.shares

  # Tags
  tags = var.tags

  # Telemetry
  enable_telemetry = var.enable_telemetry
}
