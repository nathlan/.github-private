# ALZ Infrastructure Implementation Instructions

**Target Audience:** AI Agent with GitHub MCP Server Write Access
**Implementation Method:** Direct repository creation and file commits via GitHub MCP
**Status:** Ready for Implementation

---

## Overview

This document provides complete step-by-step instructions for an AI agent with GitHub MCP server write access to create and populate the ALZ infrastructure repositories. All file contents are included inline.

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

5. **Verify repositories**
   - Check both repositories are accessible
   - Verify all files are present
   - Confirm default branch is `main`

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

---

## Verification

To verify successful implementation:

```bash
# Check repositories exist
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-subscriptions

curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/.github-workflows

# List files in alz-subscriptions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/alz-subscriptions/contents

# List workflows in .github-workflows
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/nathlan/.github-workflows/contents/.github/workflows
```

Expected responses:
- Both repositories return 200 OK with repository metadata
- `alz-subscriptions` contains: main.tf, variables.tf, outputs.tf, backend.tf, README.md, .gitignore, .terraform-version, terraform.tfvars.example, landing-zones/
- `.github-workflows` contains: README.md, .github/workflows/azure-terraform-deploy.yml

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

**Grand Total:** 10 files, 2 directories across 2 repositories

---

**Implementation Ready:** All file contents and instructions are complete. Agent can proceed with execution.
