# ALZ Infrastructure Implementation Instructions

**Target Audience:** AI Agent with GitHub MCP Server Write Access
**Implementation Method:** Direct repository creation and file commits via GitHub MCP
**Status:** Ready for Implementation

---

## Overview

This document provides complete step-by-step instructions for an AI agent with GitHub MCP server write access to create and populate the ALZ infrastructure repositories. All file contents are included inline.

### Repositories to Create

1. **`nathlan/alz-subscriptions`** - Core subscription vending infrastructure
2. **`nathlan/.github-workflows`** - Reusable parent workflows for Terraform deployments
3. **`nathlan/alz-workload-template`** - Template repository for new workload repositories (contains child workflows)

The template repository enables consistent setup of new workload repositories with pre-configured workflows that call the reusable parent workflows.

## Prerequisites

- GitHub MCP server with write access configured
- Access to create repositories in the `nathlan` organization
- Ability to create files and commit to repositories

---

## Task 1: Create `nathlan/alz-subscriptions` Repository

### Step 1.1: Create Repository

Use GitHub MCP to create repository with these parameters:

```json
{
  "owner": "nathlan",
  "name": "alz-subscriptions",
  "description": "Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform)",
  "visibility": "internal",
  "has_issues": true,
  "has_projects": true,
  "has_wiki": false,
  "has_discussions": false,
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": true,
  "delete_branch_on_merge": true,
  "auto_init": true
}
```

### Step 1.2: Create File Structure

Create the following files in the `main` branch of `nathlan/alz-subscriptions`:

#### File: `README.md`

```markdown
# Azure Landing Zone Subscriptions

This repository manages Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform).

## Overview

This repository contains:
- **Landing zone `.tfvars` files** - One file per vended subscription in `landing-zones/`
- **Terraform root module** - Calls the private `terraform-azurerm-landing-zone-vending` module
- **CI/CD workflows** - Automated plan on PR, apply on merge to main

## Repository Structure

```
.
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
├── landing-zones/          # One .tfvars file per landing zone
│   ├── example-app-prod.tfvars
│   └── example-api-dev.tfvars
├── main.tf                 # Root module calling LZ vending module
├── variables.tf            # Input variable definitions
├── outputs.tf              # Module outputs
├── backend.tf              # Azure Storage backend configuration
└── terraform.tfvars.example # Example variable values
```

## How It Works

1. **Request a Landing Zone**: Use the ALZ Vending orchestrator agent (`@alz-vending`) to create a new subscription
2. **PR Created**: Agent creates a PR with a new `.tfvars` file in `landing-zones/`
3. **Review & Approve**: Platform team reviews the configuration
4. **Merge**: PR merge triggers Terraform apply via GitHub Actions
5. **Subscription Provisioned**: Azure subscription created with networking, identity, and budgets

## Usage

### Using the ALZ Vending Orchestrator

```
@alz-vending

workload_name: my-app
environment: Production
location: uksouth
team_name: platform-engineering
address_space: 10.100.0.0/24
cost_center: IT-12345
```

### Manual Landing Zone Creation

If not using the orchestrator agent, you can manually create a `.tfvars` file:

1. Copy `terraform.tfvars.example` to `landing-zones/your-workload-name.tfvars`
2. Update all values for your workload
3. Create a PR with the new file
4. Request review from platform team
5. Merge to provision

## Terraform State

State is stored in Azure Storage with one state file per landing zone:
- Resource Group: `rg-terraform-state`
- Storage Account: `stterraformstate`
- Container: `alz-subscriptions`
- State File: `landing-zones/{workload-name}.tfstate`

## Required Secrets

GitHub Actions workflows require these repository secrets:
- `AZURE_CLIENT_ID` - Service principal client ID (OIDC)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Management subscription ID

Configure these in: Settings → Secrets and variables → Actions

## Branch Protection

The `main` branch is protected:
- Require pull request reviews (1 approver)
- Require status checks to pass (terraform-plan)
- Dismiss stale reviews on new commits
- Restrict push access to platform team

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- See the ALZ Vending documentation in `nathlan/.github-private`

## Related Repositories

- **LZ Vending Module**: `nathlan/terraform-azurerm-landing-zone-vending` v1.1.0
- **ALZ Orchestrator Config**: `nathlan/.github-private`
- **Reusable Workflows**: `nathlan/.github-workflows`
```

#### File: `.gitignore`

```
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Terraform variables (contains sensitive data)
*.auto.tfvars
*.auto.tfvars.json

# Ignore CLI configuration files
.terraform.d/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# OS
Thumbs.db
```

#### File: `.terraform-version`

```
1.9.0
```

#### File: `main.tf`

```hcl
# ==============================================================================
# Azure Landing Zone Subscription Vending
# ==============================================================================
# This root module calls the private LZ vending module to provision Corp
# landing zones with subscription, networking, identity, and budgets.
#
# Each landing zone is defined in a separate .tfvars file in landing-zones/
# ==============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

# ==============================================================================
# Landing Zone Vending Module
# ==============================================================================
# Provisions a complete Azure Landing Zone including:
# - Subscription creation and management group association
# - Virtual network with hub peering
# - User-managed identity with OIDC federated credentials
# - Role assignments for workload identity
# - Budget with notification thresholds
# ==============================================================================

module "landing_zone" {
  source = "github.com/nathlan/terraform-azurerm-landing-zone-vending?ref=v1.1.0"

  # Subscription Configuration
  subscription_alias_enabled                        = var.subscription_alias_enabled
  subscription_billing_scope                        = var.subscription_billing_scope
  subscription_display_name                         = var.subscription_display_name
  subscription_alias_name                           = var.subscription_alias_name
  subscription_workload                             = var.subscription_workload
  subscription_management_group_id                  = var.subscription_management_group_id
  subscription_management_group_association_enabled = var.subscription_management_group_association_enabled
  subscription_tags                                 = var.subscription_tags

  # Resource Groups
  resource_group_creation_enabled = var.resource_group_creation_enabled
  resource_groups                 = var.resource_groups

  # Role Assignments
  role_assignment_enabled = var.role_assignment_enabled
  role_assignments        = var.role_assignments

  # Virtual Network
  virtual_network_enabled = var.virtual_network_enabled
  virtual_networks        = var.virtual_networks

  # User-Managed Identities (UMI)
  umi_enabled             = var.umi_enabled
  user_managed_identities = var.user_managed_identities

  # Budgets
  budget_enabled = var.budget_enabled
  budgets        = var.budgets
}
```

#### File: `variables.tf`

```hcl
# ==============================================================================
# Input Variables for Landing Zone Vending
# ==============================================================================

variable "tfvars_file_name" {
  type        = string
  description = "Name of the tfvars file (without extension) for state key"
}

# Subscription Configuration
variable "subscription_alias_enabled" {
  type        = bool
  description = "Enable subscription alias creation"
  default     = true
}

variable "subscription_billing_scope" {
  type        = string
  description = "Billing scope for subscription creation (Enterprise Agreement enrollment account ID)"
}

variable "subscription_display_name" {
  type        = string
  description = "Display name for the subscription"
}

variable "subscription_alias_name" {
  type        = string
  description = "Alias name for the subscription (must be unique)"
}

variable "subscription_workload" {
  type        = string
  description = "Workload type (Production or DevTest)"
  default     = "Production"

  validation {
    condition     = contains(["Production", "DevTest"], var.subscription_workload)
    error_message = "Subscription workload must be either 'Production' or 'DevTest'."
  }
}

variable "subscription_management_group_id" {
  type        = string
  description = "Management group ID to associate subscription with"
  default     = "Corp"
}

variable "subscription_management_group_association_enabled" {
  type        = bool
  description = "Enable management group association"
  default     = true
}

variable "subscription_tags" {
  type        = map(string)
  description = "Tags to apply to the subscription"
  default     = {}
}

# Resource Groups
variable "resource_group_creation_enabled" {
  type        = bool
  description = "Enable resource group creation"
  default     = true
}

variable "resource_groups" {
  type        = map(any)
  description = "Resource groups to create in the subscription"
  default     = {}
}

# Role Assignments
variable "role_assignment_enabled" {
  type        = bool
  description = "Enable role assignments"
  default     = false
}

variable "role_assignments" {
  type        = map(any)
  description = "Role assignments to create"
  default     = {}
}

# Virtual Network
variable "virtual_network_enabled" {
  type        = bool
  description = "Enable virtual network creation"
  default     = true
}

variable "virtual_networks" {
  type        = map(any)
  description = "Virtual networks to create with hub peering"
  default     = {}
}

# User-Managed Identities
variable "umi_enabled" {
  type        = bool
  description = "Enable user-managed identity creation"
  default     = false
}

variable "user_managed_identities" {
  type        = map(any)
  description = "User-managed identities with OIDC federated credentials"
  default     = {}
}

# Budgets
variable "budget_enabled" {
  type        = bool
  description = "Enable budget creation"
  default     = false
}

variable "budgets" {
  type        = map(any)
  description = "Budgets with notification thresholds"
  default     = {}
}
```

#### File: `outputs.tf`

```hcl
# ==============================================================================
# Outputs from Landing Zone Vending Module
# ==============================================================================

output "subscription_id" {
  description = "The subscription ID of the vended landing zone"
  value       = module.landing_zone.subscription_id
}

output "subscription_resource_id" {
  description = "The full Azure resource ID of the subscription"
  value       = module.landing_zone.subscription_resource_id
}

output "virtual_network_resource_ids" {
  description = "Resource IDs of created virtual networks"
  value       = module.landing_zone.virtual_network_resource_ids
}

output "resource_group_resource_ids" {
  description = "Resource IDs of created resource groups"
  value       = module.landing_zone.resource_group_resource_ids
}

output "umi_client_ids" {
  description = "Client IDs of user-managed identities (for OIDC authentication)"
  value       = module.landing_zone.umi_client_ids
  sensitive   = true
}

output "umi_principal_ids" {
  description = "Principal IDs of user-managed identities (for role assignments)"
  value       = module.landing_zone.umi_principal_ids
}

output "budget_resource_ids" {
  description = "Resource IDs of created budgets"
  value       = module.landing_zone.budget_resource_ids
}
```

#### File: `backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "alz-subscriptions"
    key                  = "landing-zones/${var.tfvars_file_name}.tfstate"
    use_oidc             = true
  }
}
```

#### File: `terraform.tfvars.example`

```hcl
# ==============================================================================
# Example Terraform Variables File
# ==============================================================================
# Copy this file to landing-zones/your-workload-name.tfvars and customize
# ==============================================================================

# REQUIRED: State file name (should match your workload name)
tfvars_file_name = "your-workload-name"

# REQUIRED: Subscription Configuration
subscription_alias_enabled    = true
subscription_billing_scope    = "PLACEHOLDER_BILLING_SCOPE" # Get from Azure EA
subscription_display_name     = "your-workload-name (Production)"
subscription_alias_name       = "sub-your-workload-prod"
subscription_workload         = "Production" # or "DevTest"
subscription_management_group_id = "Corp"
subscription_management_group_association_enabled = true

subscription_tags = {
  Environment = "Production"
  Workload    = "your-workload-name"
  CostCenter  = "YOUR-COST-CENTER"
  ManagedBy   = "Terraform"
  Owner       = "TEAM-NAME"
  CreatedDate = "YYYY-MM-DD"
}

# Resource Groups
resource_group_creation_enabled = true
resource_groups = {
  rg_workload = {
    name     = "rg-your-workload-prod"
    location = "uksouth"
  }
  rg_identity = {
    name     = "rg-your-workload-identity"
    location = "uksouth"
  }
}

# Virtual Network with Hub Peering
virtual_network_enabled = true
virtual_networks = {
  spoke = {
    name                    = "vnet-your-workload-prod-uksouth"
    resource_group_key      = "rg_workload"
    address_space           = ["10.X.Y.0/24"] # Get unique CIDR from platform team
    location                = "uksouth"
    hub_peering_enabled     = true
    hub_network_resource_id = "PLACEHOLDER_HUB_VNET_ID" # Get from platform team

    subnets = {
      default = {
        name             = "snet-default"
        address_prefixes = ["10.X.Y.0/26"]
      }
    }
  }
}

# OPTIONAL: User-Managed Identity with GitHub OIDC
# Uncomment and configure if you need workload identity federation
# umi_enabled = true
# user_managed_identities = {
#   deploy = {
#     name               = "umi-your-workload-deploy"
#     location           = "uksouth"
#     resource_group_key = "rg_identity"
#
#     role_assignments = {
#       subscription_contributor = {
#         scope_resource_id       = "subscription"
#         role_definition_id_or_name = "Contributor"
#       }
#     }
#
#     federated_credentials_github = {
#       main = {
#         name         = "github-main"
#         organization = "nathlan"
#         repository   = "your-repo-name"
#         entity       = "ref:refs/heads/main"
#       }
#     }
#   }
# }

# OPTIONAL: Monthly Budget with Notifications
# Uncomment and configure to enable cost monitoring
# budget_enabled = true
# budgets = {
#   monthly = {
#     name              = "Monthly Budget"
#     amount            = 500
#     time_grain        = "Monthly"
#     time_period_start = "YYYY-MM-01T00:00:00Z"
#     time_period_end   = "YYYY-12-31T23:59:59Z"
#
#     notifications = {
#       threshold_80 = {
#         enabled        = true
#         operator       = "GreaterThan"
#         threshold      = 80
#         contact_emails = ["your-email@example.com"]
#         threshold_type = "Actual"
#       }
#     }
#   }
# }
```

#### Directory: `landing-zones/`

Create an empty directory `landing-zones/` (you can add a `.gitkeep` file if needed).

---

## Task 2: Create `nathlan/.github-workflows` Repository

### Step 2.1: Create Repository

Use GitHub MCP to create repository with these parameters:

```json
{
  "owner": "nathlan",
  "name": ".github-workflows",
  "description": "Reusable GitHub Actions workflows for Terraform deployments",
  "visibility": "internal",
  "has_issues": true,
  "has_projects": false,
  "has_wiki": false,
  "has_discussions": false,
  "auto_init": true
}
```

### Step 2.2: Create File Structure

Create the following files in the `main` branch of `nathlan/.github-workflows`:

#### File: `README.md`

```markdown
# Reusable GitHub Actions Workflows

This repository contains reusable GitHub Actions workflows for Terraform deployments across the organization.

## Available Workflows

### Azure Terraform Deploy

**File:** `.github/workflows/azure-terraform-deploy.yml`

**Purpose:** Reusable workflow for Azure Terraform deployments with OIDC authentication, security scanning, and approval gates.

**Usage:**

```yaml
jobs:
  deploy:
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: production
      terraform-version: '1.9.0'
      working-directory: terraform
      azure-region: uksouth
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**Features:**

- ✅ Azure OIDC authentication (no stored credentials)
- ✅ Security scanning with Checkov (fails on violations)
- ✅ TFLint validation
- ✅ Plan artifact reuse (prevents drift)
- ✅ Environment protection with manual approvals
- ✅ Comprehensive PR comments with plan output

**Workflow Jobs:**

1. **validate** - Terraform format, validation, TFLint checks
2. **security** - Checkov security scanning with SARIF upload
3. **plan** - Generate Terraform plan (with PR comments)
4. **apply** - Deploy with approval gate (main branch only)

**Required Secrets:**

- `AZURE_CLIENT_ID` - Service principal client ID (OIDC)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

**Required Environment:**

Create an environment in your repository (e.g., `production`) with:
- Required reviewers (platform team members)
- Environment secrets (listed above)

## Documentation

For detailed usage instructions and troubleshooting, see:
- Workflow file comments in `.github/workflows/azure-terraform-deploy.yml`
- Example implementation in `nathlan/.github-private` repository
- Deployment guides in `docs/DEPLOYMENT.md` (if available)

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- Reference the ALZ vending documentation
```

#### File: `.github/workflows/azure-terraform-deploy.yml`

**Note:** Copy the contents from the source repository at `.github/workflows/azure-terraform-deploy-reusable.yml` in `nathlan/.github-private`.

The agent should read the file from:
- Repository: `nathlan/.github-private`
- Branch: `main`
- Path: `.github/workflows/azure-terraform-deploy-reusable.yml`

And create it at:
- Repository: `nathlan/.github-workflows`
- Branch: `main`
- Path: `.github/workflows/azure-terraform-deploy.yml`

---

## Task 3: Create `nathlan/alz-workload-template` Repository

### Step 3.1: Create Template Repository

Use GitHub MCP to create repository with these parameters:

```json
{
  "owner": "nathlan",
  "name": "alz-workload-template",
  "description": "Template repository for ALZ workload repositories with pre-configured Terraform workflows",
  "visibility": "internal",
  "has_issues": true,
  "has_projects": false,
  "has_wiki": false,
  "has_discussions": false,
  "is_template": true,
  "auto_init": true
}
```

**Important:** Note the `"is_template": true` parameter - this makes it a GitHub template repository.

### Step 3.2: Create File Structure

Create the following files in the `main` branch of `nathlan/alz-workload-template`:

#### File: `README.md`

```markdown
# [Workload Name] - Azure Landing Zone

> **Note:** This repository was created from the ALZ workload template. Update this README with your workload-specific information.

## Overview

This repository contains the Infrastructure as Code (Terraform) for the `[workload-name]` Azure Landing Zone.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # CI/CD workflow for Terraform
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Outputs
│   └── terraform.tf                # Provider and backend config
├── .gitignore                      # Git ignore patterns
└── README.md                       # This file
```

## Deployment Workflow

This repository uses a parent/child workflow pattern:
- **Parent workflow:** `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml` (reusable)
- **Child workflow:** `.github/workflows/terraform-deploy.yml` (this repo)

### Workflow Triggers

- **Pull Requests:** Validates, scans, and plans changes (no apply)
- **Push to main:** Deploys to production with manual approval gate
- **Manual dispatch:** Allows selecting environment for deployment

## Getting Started

### 1. Configure Repository Secrets

Add these secrets in **Settings → Secrets and variables → Actions**:

```
AZURE_CLIENT_ID       - Service principal client ID (OIDC)
AZURE_TENANT_ID       - Azure tenant ID
AZURE_SUBSCRIPTION_ID - Azure subscription ID
```

### 2. Create Environment

Create a **production** environment in **Settings → Environments**:
- Enable "Required reviewers" and add platform team members
- Optionally configure deployment branches (e.g., only main)
- Add the same secrets as above at the environment level

### 3. Configure Terraform Backend

Update `terraform/terraform.tf` with your backend configuration:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "[workload-name]-production.tfstate"
    use_oidc             = true
  }
}
```

### 4. Add Your Infrastructure Code

Add your Terraform resources to the `terraform/` directory:
- Use `main.tf` for resource definitions
- Define variables in `variables.tf`
- Expose outputs in `outputs.tf`

### 5. Create a Pull Request

1. Create a feature branch
2. Add your Terraform changes
3. Push and create a PR
4. Review the Terraform plan in PR comments
5. Get approval from the platform team
6. Merge to trigger deployment

## Azure OIDC Setup

If not already configured, set up Azure OIDC for this repository:

```bash
# Get the App Registration ID
APP_ID="<your-app-id>"
REPO_NAME="<this-repo-name>"

# Add federated credential for this repository
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-${REPO_NAME}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:nathlan/${REPO_NAME}:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

## Support

For questions or issues:
- Create an issue in this repository
- Contact the platform engineering team
- Reference the ALZ vending documentation in `nathlan/.github-private`

## Related Repositories

- **ALZ Subscriptions:** `nathlan/alz-subscriptions` - Subscription vending infrastructure
- **Reusable Workflows:** `nathlan/.github-workflows` - Central workflow definitions
- **LZ Vending Module:** `nathlan/terraform-azurerm-landing-zone-vending`
```

#### File: `.gitignore`

```
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Terraform variables (may contain sensitive data)
*.auto.tfvars
*.auto.tfvars.json

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# OS
Thumbs.db
```

#### File: `.github/workflows/terraform-deploy.yml`

```yaml
name: Terraform Deployment

# ============================================================================
# CHILD WORKFLOW - Calls Reusable Parent Workflow
# ============================================================================
# This workflow calls the centralized reusable workflow for Azure Terraform
# deployments. The parent workflow handles validation, security scanning,
# planning, and deployment with OIDC authentication.
# ============================================================================

on:
  # Trigger on pushes to main branch (after PR merge)
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-deploy.yml'

  # Trigger on pull requests to main (for plan validation)
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-deploy.yml'

  # Allow manual triggering for testing and emergency deployments
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment for deployment'
        required: false
        type: choice
        options:
          - production
          - staging
          - development
        default: 'production'

permissions:
  contents: read
  pull-requests: write
  id-token: write
  issues: write

jobs:
  # Call the parent reusable workflow from the central repository
  deploy:
    name: Deploy to Azure
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main

    with:
      # REQUIRED: Deployment environment (must match environment in repo settings)
      environment: ${{ inputs.environment || 'production' }}

      # OPTIONAL: Override Terraform version if needed (default: 1.9.0)
      terraform-version: '1.9.0'

      # REQUIRED: Working directory containing Terraform code
      working-directory: 'terraform'

      # OPTIONAL: Azure region (default: uksouth)
      azure-region: 'uksouth'

    secrets:
      # REQUIRED: Azure OIDC credentials (configure in repository settings)
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

#### Directory: `terraform/`

Create the `terraform/` directory with the following files:

#### File: `terraform/main.tf`

```hcl
# ==============================================================================
# Main Terraform Configuration
# ==============================================================================
# Add your Azure resources here
#
# Example:
# resource "azurerm_resource_group" "main" {
#   name     = var.resource_group_name
#   location = var.location
#   tags     = var.tags
# }
# ==============================================================================

# Placeholder - Add your resources here
```

#### File: `terraform/variables.tf`

```hcl
# ==============================================================================
# Input Variables
# ==============================================================================

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "uksouth"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., production, staging, development)"
  default     = "production"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    ManagedBy = "Terraform"
    Source    = "nathlan/alz-workload-template"
  }
}
```

#### File: `terraform/outputs.tf`

```hcl
# ==============================================================================
# Outputs
# ==============================================================================
# Define outputs to expose information about created resources
#
# Example:
# output "resource_group_id" {
#   description = "The ID of the resource group"
#   value       = azurerm_resource_group.main.id
# }
# ==============================================================================

# Placeholder - Add your outputs here
```

#### File: `terraform/terraform.tf`

```hcl
# ==============================================================================
# Terraform and Provider Configuration
# ==============================================================================

terraform {
  required_version = ">= 1.9.0"

  # Configure Azure backend for remote state
  # UPDATE THIS with your actual backend configuration
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "workload-template.tfstate" # UPDATE: Change to your workload name
    use_oidc             = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}
```

### Step 3.3: Mark as Template

Ensure the repository is marked as a template repository. This is set via the `"is_template": true` parameter during creation, but can also be configured via:
- Repository Settings → Template repository checkbox
- Or via GitHub API: `PATCH /repos/nathlan/alz-workload-template` with `{"is_template": true}`

---

## Implementation Steps Summary

For the agent to execute:

1. **Create `nathlan/alz-subscriptions` repository**
   - Use repository creation API/MCP
   - Set internal visibility
   - Enable issues and projects

2. **Populate `alz-subscriptions` with files**
   - Create 8 files listed above in root directory
   - Create `landing-zones/` directory
   - Commit message: "Initial commit: ALZ subscription vending infrastructure"

3. **Create `nathlan/.github-workflows` repository**
   - Use repository creation API/MCP
   - Set internal visibility
   - Enable issues

4. **Populate `.github-workflows` with files**
   - Create `README.md` in root
   - Create `.github/workflows/` directory
   - Copy `azure-terraform-deploy-reusable.yml` from `.github-private` to `azure-terraform-deploy.yml`
   - Commit message: "Initial commit: Add reusable Azure Terraform workflow"

5. **Create `nathlan/alz-workload-template` repository**
   - Use repository creation API/MCP
   - Set internal visibility
   - **Set `is_template: true`** (critical for template functionality)
   - Enable issues

6. **Populate `alz-workload-template` with files**
   - Create `README.md` in root
   - Create `.gitignore` in root
   - Create `.github/workflows/` directory
   - Create `terraform-deploy.yml` in `.github/workflows/`
   - Create `terraform/` directory
   - Create 4 Terraform files in `terraform/` (main.tf, variables.tf, outputs.tf, terraform.tf)
   - Commit message: "Initial commit: ALZ workload template with Terraform workflow"

7. **Verify repositories**
   - Check all three repositories are accessible
   - Verify all files are present
   - Confirm default branch is `main`
   - **Verify `alz-workload-template` is marked as a template repository**

---

## Post-Implementation Configuration

After the agent creates these repositories, manual configuration is required:

### For `alz-subscriptions`:

1. **Configure GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

2. **Create Environment** (Settings → Environments):
   - Name: `azure-landing-zones`
   - Add required reviewers
   - Add environment secrets (same as above)

3. **Set Branch Protection** (Settings → Branches):
   - Branch: `main`
   - Require pull request reviews (1 approver)
   - Require status checks to pass
   - Dismiss stale reviews

4. **Update Azure Configuration** in `nathlan/.github-private`:
   - Edit `agents/alz-vending.agent.md`
   - Replace PLACEHOLDER values for:
     - `tenant_id`
     - `billing_scope`
     - `hub_network_resource_id`

### For `.github-workflows`:

No additional configuration required. The workflow is ready to be called by other repositories.

### For `alz-workload-template`:

No additional configuration required. This is a template repository ready to be used when creating new workload repositories.

**Usage:** When creating a new workload repository (either manually or via ALZ vending orchestrator):
1. Use "Use this template" button on GitHub UI, or
2. Via API: `POST /repos/nathlan/alz-workload-template/generate` with target repo name
3. The new repository will be created with all template files pre-configured

---

## Verification

To verify successful implementation:

```bash
# Check repositories exist
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-subscriptions

curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/.github-workflows

curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-workload-template

# Verify template repo is marked as template
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-workload-template | jq '.is_template'
# Expected: true

# List files in alz-subscriptions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-subscriptions/contents

# List workflows in .github-workflows
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/.github-workflows/contents/.github/workflows

# List files in template repo
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-workload-template/contents
```

Expected responses:
- All three repositories return 200 OK with repository metadata
- `alz-workload-template.is_template` is `true`
- `alz-subscriptions` contains: main.tf, variables.tf, outputs.tf, backend.tf, README.md, .gitignore, .terraform-version, terraform.tfvars.example, landing-zones/
- `.github-workflows` contains: README.md, .github/workflows/azure-terraform-deploy.yml
- `alz-workload-template` contains: README.md, .gitignore, .github/workflows/terraform-deploy.yml, terraform/ (with 4 files)

---

## File Count Summary

**Repository 1: `nathlan/alz-subscriptions`**
- 8 files in root
- 1 directory (landing-zones)
- Total: 8 files + 1 directory

**Repository 2: `nathlan/.github-workflows`**
- 1 file in root (README.md)
- 1 directory (.github/workflows/)
- 1 file in .github/workflows/ (azure-terraform-deploy.yml)
- Total: 2 files + 1 directory

**Repository 3: `nathlan/alz-workload-template` (Template)**
- 2 files in root (README.md, .gitignore)
- 1 directory (.github/workflows/)
- 1 file in .github/workflows/ (terraform-deploy.yml)
- 1 directory (terraform/)
- 4 files in terraform/ (main.tf, variables.tf, outputs.tf, terraform.tf)
- Total: 7 files + 2 directories

**Grand Total:** 17 files, 4 directories across 3 repositories

---

## Using the Template Repository

When the ALZ vending orchestrator (or GitHub config agent) creates a new workload repository, it should use this template:

### Via GitHub API:

```bash
POST /repos/nathlan/alz-workload-template/generate
{
  "owner": "nathlan",
  "name": "workload-app-name",
  "description": "Azure Landing Zone for app-name workload",
  "include_all_branches": false,
  "private": false
}
```

### Via GitHub UI:

1. Navigate to `https://github.com/nathlan/alz-workload-template`
2. Click "Use this template" button
3. Fill in new repository name
4. Click "Create repository from template"

### Benefits:

- New workload repositories start with complete workflow setup
- Terraform directory structure pre-configured
- Child workflow already calling parent reusable workflow
- Documentation template ready to customize
- Consistent structure across all workload repositories

---

**Implementation Ready:** All file contents and instructions are complete. Agent can proceed with execution.
