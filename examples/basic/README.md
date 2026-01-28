# Basic Example - Azure App Service Module

This example demonstrates the basic usage of the Azure App Service Terraform module with a Node.js application stack.

## Features Demonstrated

- App Service Plan with Linux OS
- App Service / Web App with Node.js 20 LTS runtime
- HTTPS-only configuration
- TLS 1.3 minimum version
- System-assigned managed identity
- Custom app settings
- Resource tagging

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. After deployment, access your App Service using the output URL.

## Cleanup

To destroy the resources:
```bash
terraform destroy
```

## Outputs

- `app_service_url` - The HTTPS URL of the deployed App Service
- `app_service_name` - The name of the App Service
- `app_service_plan_name` - The name of the App Service Plan

## Notes

- This example creates resources in the East US region
- The App Service Plan uses the P1v3 SKU (Premium v3)
- All resources are tagged for easy identification
- System-assigned managed identity is enabled for secure Azure service authentication
