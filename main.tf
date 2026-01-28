# Generate unique names for resources
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

locals {
  app_service_plan_name = "${var.name}-plan-${random_string.unique.result}"
  app_service_name      = "${var.name}-app-${random_string.unique.result}"

  # Construct site_config object for the web app
  site_config = {
    always_on                         = var.always_on
    minimum_tls_version               = var.minimum_tls_version
    ftps_state                        = var.ftps_state
    http2_enabled                     = var.http2_enabled
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time_in_min
    vnet_route_all_enabled            = var.vnet_route_all_enabled

    # Application stack configuration
    application_stack = var.application_stack != null ? {
      default = var.application_stack
    } : {}

    # IP restrictions configuration
    ip_restriction = var.ip_restrictions
  }

  # Convert connection_strings to the format expected by the AVM module
  connection_strings_formatted = {
    for key, value in var.connection_strings : key => {
      name  = key
      type  = value.type
      value = value.value
    }
  }

  # Merge default tags with user-provided tags
  tags = merge(
    {
      "ManagedBy"   = "Terraform"
      "Module"      = "terraform-azurerm-app-service"
      "Environment" = "Production"
    },
    var.tags
  )
}

# Deploy App Service Plan using Azure Verified Module
module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "~> 1.0"

  name                       = local.app_service_plan_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  os_type                    = var.os_type
  sku_name                   = var.sku_name
  worker_count               = var.worker_count
  zone_balancing_enabled     = var.zone_balancing_enabled
  per_site_scaling_enabled   = var.per_site_scaling_enabled
  app_service_environment_id = var.app_service_environment_id
  tags                       = local.tags
  enable_telemetry           = var.enable_telemetry
  lock                       = var.lock
  role_assignments           = var.role_assignments_plan
}

# Deploy App Service / Web App using Azure Verified Module
module "app_service" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.19"

  name                     = local.app_service_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  service_plan_resource_id = module.app_service_plan.resource_id

  # Required parameters
  kind    = "webapp"
  os_type = var.os_type

  # Web App Configuration
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  client_affinity_enabled       = var.client_affinity_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  virtual_network_subnet_id     = var.virtual_network_subnet_id

  # Site configuration
  site_config = local.site_config

  # App settings and connection strings
  app_settings       = var.app_settings
  connection_strings = local.connection_strings_formatted

  # Managed identity
  managed_identities = var.managed_identities

  # Tags and telemetry
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  # Role assignments
  role_assignments = var.role_assignments_app
}
