variable "name" {
  type        = string
  description = "The name of the storage account. Must be between 3 and 24 characters and globally unique."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be between 3 and 24 characters, lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the storage account."
}

variable "location" {
  type        = string
  description = "Azure region for the storage account. Only australiaeast and australiasoutheast are allowed."

  validation {
    condition     = contains(["australiaeast", "australiasoutheast"], var.location)
    error_message = "Location must be either 'australiaeast' or 'australiasoutheast'."
  }
}

variable "account_tier" {
  type        = string
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either 'Standard' or 'Premium'."
  }
}

variable "account_replication_type" {
  type        = string
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Account replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "containers" {
  type = map(object({
    name                  = string
    public_access         = optional(string, "None")
    metadata              = optional(map(string))
    container_access_type = optional(string, "private")
  }))
  description = "Map of blob containers to create. Each container supports name, public_access (None, Blob, Container), metadata, and container_access_type."
  default     = {}
}

variable "blob_properties" {
  type = object({
    versioning_enabled            = optional(bool, true)
    change_feed_enabled           = optional(bool, false)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool, true)

    container_delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), { days = 7 })

    delete_retention_policy = optional(object({
      days                     = optional(number, 7)
      permanent_delete_enabled = optional(bool, false)
    }), { days = 7 })

    restore_policy = optional(object({
      days = number
    }))
  })
  description = "Blob service properties for the storage account with secure defaults."
  default     = {}
}

variable "min_tls_version" {
  type        = string
  description = "The minimum supported TLS version for the storage account."
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "Minimum TLS version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is allowed for this storage account. Defaults to false for security."
  default     = false
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  description = "Allow or disallow nested items within this Account to opt into being public. Defaults to false for security."
  default     = false
}

variable "shared_access_key_enabled" {
  type        = bool
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. Defaults to false for enhanced security."
  default     = false
}

variable "https_traffic_only_enabled" {
  type        = bool
  description = "Boolean flag which forces HTTPS if enabled. Defaults to true for security."
  default     = true
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  description = "Should cross Tenant replication be enabled? Defaults to false for security."
  default     = false
}

variable "network_rules" {
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(set(string), ["AzureServices"])
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
  })
  description = "Network rules for the storage account. Defaults to denying all traffic except Azure Services."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default     = {}
}

variable "enable_telemetry" {
  type        = bool
  description = "Controls whether telemetry is enabled for the AVM module. Defaults to true."
  default     = true
}
