variable "name" {
  type        = string
  description = "The name of the App Service. This will be used to generate unique names for the App Service Plan and App Service."

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 60
    error_message = "The name must be between 1 and 60 characters long."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the App Service resources."
}

variable "location" {
  type        = string
  description = "The Azure region where the App Service resources should be created."
}

variable "os_type" {
  type        = string
  description = "The operating system type for the App Service Plan. Valid values are 'Linux', 'Windows', or 'WindowsContainer'."
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows", "WindowsContainer"], var.os_type)
    error_message = "The os_type must be either 'Linux', 'Windows', or 'WindowsContainer'."
  }
}

variable "sku_name" {
  type        = string
  description = "The SKU name for the App Service Plan. Examples: 'B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2', 'P1v3', 'P2v3', 'P3v3'."
  default     = "P1v3"
}

variable "worker_count" {
  type        = number
  description = "The number of workers to allocate for this App Service Plan."
  default     = 1

  validation {
    condition     = var.worker_count > 0 && var.worker_count <= 30
    error_message = "The worker_count must be between 1 and 30."
  }
}

variable "zone_balancing_enabled" {
  type        = bool
  description = "Should zone balancing be enabled for this App Service Plan? Defaults to false. Set to true for production workloads."
  default     = false
}

variable "per_site_scaling_enabled" {
  type        = bool
  description = "Should per site scaling be enabled for this App Service Plan?"
  default     = false
}

variable "app_service_environment_id" {
  type        = string
  description = "The ID of the App Service Environment to deploy the App Service Plan in. Leave null for multi-tenant deployment."
  default     = null
}

# Web App / App Service Variables

variable "always_on" {
  type        = bool
  description = "Should the App Service be always on? Recommended for production workloads."
  default     = true
}

variable "https_only" {
  type        = bool
  description = "Should the App Service only be accessible over HTTPS?"
  default     = true
}

variable "minimum_tls_version" {
  type        = string
  description = "The minimum TLS version for the App Service. Valid values are '1.0', '1.1', '1.2', '1.3'."
  default     = "1.3"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.minimum_tls_version)
    error_message = "The minimum_tls_version must be '1.0', '1.1', '1.2', or '1.3'."
  }
}

variable "ftps_state" {
  type        = string
  description = "The FTPS state for the App Service. Valid values are 'AllAllowed', 'FtpsOnly', 'Disabled'."
  default     = "FtpsOnly"

  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "The ftps_state must be 'AllAllowed', 'FtpsOnly', or 'Disabled'."
  }
}

variable "http2_enabled" {
  type        = bool
  description = "Should HTTP/2 be enabled for the App Service?"
  default     = true
}

variable "application_stack" {
  type = object({
    dotnet_version              = optional(string)
    dotnet_core_version         = optional(string)
    java_version                = optional(string)
    node_version                = optional(string)
    python_version              = optional(string)
    php_version                 = optional(string)
    go_version                  = optional(string)
    ruby_version                = optional(string)
    use_dotnet_isolated_runtime = optional(bool)
    docker_image_name           = optional(string)
    docker_registry_url         = optional(string)
    docker_registry_username    = optional(string)
    docker_registry_password    = optional(string)
  })
  description = <<-EOT
    Configuration for the application stack. Specify the runtime and version for your application.
    Examples:
    - For .NET 8: { dotnet_version = "8.0" }
    - For Node.js: { node_version = "20-lts" }
    - For Python: { python_version = "3.11" }
    - For Java: { java_version = "17" }
    - For Docker: { docker_image_name = "myapp:latest", docker_registry_url = "https://myregistry.azurecr.io" }
  EOT
  default     = null
}

variable "app_settings" {
  type        = map(string)
  description = "A map of key-value pairs for App Settings for the App Service."
  default     = {}
}

variable "connection_strings" {
  type = map(object({
    type  = string
    value = string
  }))
  description = "A map of connection strings for the App Service. Each connection string requires 'type' and 'value'."
  default     = {}
}

variable "health_check_path" {
  type        = string
  description = "The path to use for health checks. If not set, health checks are disabled."
  default     = null
}

variable "health_check_eviction_time_in_min" {
  type        = number
  description = "The time in minutes after which unhealthy instances are removed."
  default     = null
}

variable "vnet_route_all_enabled" {
  type        = bool
  description = "Should all outbound traffic from the App Service be routed through the VNet?"
  default     = false
}

variable "virtual_network_subnet_id" {
  type        = string
  description = "The ID of the subnet to integrate the App Service with for VNet integration."
  default     = null
}

variable "ip_restrictions" {
  type = map(object({
    action                    = optional(string, "Allow")
    ip_address                = optional(string)
    name                      = optional(string)
    priority                  = optional(number, 65000)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
  }))
  description = "A map of IP restriction rules for the App Service."
  default     = {}
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  description = <<-EOT
    Managed identities to be created for the App Service.
    - system_assigned: Enable system-assigned managed identity
    - user_assigned_resource_ids: Set of user-assigned managed identity resource IDs
  EOT
  default = {
    system_assigned = false
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources."
  default     = {}
}

variable "enable_telemetry" {
  type        = bool
  description = "This variable controls whether or not telemetry is enabled for the module. For more information see https://aka.ms/avm/telemetryinfo."
  default     = true
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  description = <<-EOT
    Controls the Resource Lock configuration for the App Service Plan. The following properties can be specified:
    - `kind` - (Required) The type of lock. Possible values are 'CanNotDelete' and 'ReadOnly'.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value.
  EOT
  default     = null
}

variable "role_assignments_plan" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  description = "A map of role assignments to create on the App Service Plan."
  default     = {}
}

variable "role_assignments_app" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  description = "A map of role assignments to create on the App Service / Web App."
  default     = {}
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Should public network access be enabled for the App Service?"
  default     = true
}

variable "client_affinity_enabled" {
  type        = bool
  description = "Should client affinity be enabled for the App Service?"
  default     = false
}

variable "client_certificate_enabled" {
  type        = bool
  description = "Should client certificates be enabled for the App Service?"
  default     = false
}

variable "client_certificate_mode" {
  type        = string
  description = "The client certificate mode. Valid values are 'Required', 'Optional', 'OptionalInteractiveUser'."
  default     = "Optional"

  validation {
    condition     = contains(["Required", "Optional", "OptionalInteractiveUser"], var.client_certificate_mode)
    error_message = "The client_certificate_mode must be 'Required', 'Optional', or 'OptionalInteractiveUser'."
  }
}
