output "app_service_plan_id" {
  description = "The ID of the App Service Plan."
  value       = module.app_service_plan.resource_id
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan."
  value       = module.app_service_plan.name
}

output "app_service_id" {
  description = "The ID of the App Service / Web App."
  value       = module.app_service.resource_id
}

output "app_service_name" {
  description = "The name of the App Service / Web App."
  value       = module.app_service.name
}

output "app_service_default_hostname" {
  description = "The default hostname of the App Service."
  value       = module.app_service.resource.default_hostname
}

output "app_service_default_site_hostname" {
  description = "The default site hostname of the App Service."
  value       = "https://${module.app_service.resource.default_hostname}"
}

output "app_service_outbound_ip_addresses" {
  description = "A comma-separated list of outbound IP addresses for the App Service."
  value       = module.app_service.resource.outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "A comma-separated list of possible outbound IP addresses for the App Service."
  value       = module.app_service.resource.possible_outbound_ip_addresses
}

output "app_service_identity" {
  description = "The identity block of the App Service containing principal_id and tenant_id."
  value       = module.app_service.resource.identity
  sensitive   = true
}

output "app_service_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity for the App Service."
  value       = try(module.app_service.resource.identity[0].principal_id, null)
}

output "app_service_custom_domain_verification_id" {
  description = "The custom domain verification ID for the App Service."
  value       = module.app_service.resource.custom_domain_verification_id
  sensitive   = true
}

output "app_service_plan_resource" {
  description = "The full App Service Plan resource object."
  value       = module.app_service_plan.resource
}

output "app_service_resource" {
  description = "The full App Service resource object."
  value       = module.app_service.resource
  sensitive   = true
}
