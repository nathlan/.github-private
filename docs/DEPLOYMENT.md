# Azure Terraform Deployment Guide

## Overview

This repository uses a **parent/child workflow pattern** for Azure Terraform deployments. This approach provides standardized, secure, and automated infrastructure deployments across the organization.

## Workflow Architecture

```
┌─────────────────────────────────────────┐
│  Child Workflow (Your Repository)      │
│  .github/workflows/terraform-deploy.yml │
└─────────────┬───────────────────────────┘
              │ calls
              ▼
┌─────────────────────────────────────────┐
│  Parent Reusable Workflow               │
│  nathlan/.github-workflows              │
│  /.github/workflows/                    │
│   azure-terraform-deploy.yml            │
│                                         │
│  Jobs:                                  │
│  1. validate  → Format, validate, lint  │
│  2. security  → Checkov scanning        │
│  3. plan      → Generate plan           │
│  4. apply     → Deploy (approval gate)  │
└─────────────────────────────────────────┘
```

## Prerequisites

### 1. Azure Setup

#### Create Service Principal with OIDC

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
APP_NAME="github-actions-terraform"
REPO_ORG="your-org"
REPO_NAME="your-repo"

# Create Azure AD App Registration and Service Principal
az ad sp create-for-rbac \
  --name "${APP_NAME}" \
  --role contributor \
  --scopes "/subscriptions/${SUBSCRIPTION_ID}"

# Note the output: appId, tenant
# You'll need these for the next steps

# Get the Application Object ID
APP_ID="<appId from previous command>"
OBJECT_ID=$(az ad app show --id ${APP_ID} --query id -o tsv)

# Add federated credential for main branch
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --body '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'${REPO_ORG}'/'${REPO_NAME}':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Optionally, add federated credential for pull requests
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --body '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'${REPO_ORG}'/'${REPO_NAME}':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### Create Storage Account for Terraform State

```bash
# Set variables
RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstate${RANDOM}"
CONTAINER_NAME="tfstate"
LOCATION="uksouth"

# Create resource group
az group create \
  --name ${RESOURCE_GROUP} \
  --location ${LOCATION}

# Create storage account
az storage account create \
  --name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION} \
  --sku Standard_LRS \
  --encryption-services blob

# Create blob container
az storage container create \
  --name ${CONTAINER_NAME} \
  --account-name ${STORAGE_ACCOUNT} \
  --auth-mode login

# Grant service principal access to storage account
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee ${APP_ID} \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"
```

### 2. GitHub Repository Setup

#### Configure Secrets

Navigate to: **Settings → Secrets and variables → Actions → Secrets**

Add the following repository secrets:

| Secret Name | Value | Where to Find |
|------------|-------|---------------|
| `AZURE_CLIENT_ID` | Application (client) ID | Azure Portal → App Registrations → Your App |
| `AZURE_TENANT_ID` | Directory (tenant) ID | Azure Portal → Azure Active Directory → Overview |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | Azure Portal → Subscriptions |

#### Configure Environment Protection

Navigate to: **Settings → Environments → New environment**

1. **Create environment**: `production`
2. **Configure protection rules**:
   - ✅ **Required reviewers**: Add team members who can approve deployments
   - ✅ **Wait timer** (optional): Add delay before deployment (e.g., 5 minutes)
   - ✅ **Deployment branches**: Select "Selected branches" → Add `main`
3. **Save protection rules**

Repeat for additional environments (e.g., `staging`, `development`) if needed.

### 3. Terraform Configuration

#### Configure Backend

Create or update `terraform/terraform.tf`:

```hcl
terraform {
  required_version = ">= 1.9.0"

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345"  # Use your storage account name
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
    use_oidc            = true  # Critical: Enable OIDC authentication
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true  # Critical: Enable OIDC authentication
}
```

#### Configure Variables (Optional)

Create `terraform/variables.tf`:

```hcl
variable "azure_region" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "uksouth"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### 4. Create Workflow

Copy the example child workflow to your repository:

```bash
# Copy the example workflow
cp .github/workflows/example-azure-terraform-child.yml \
   .github/workflows/terraform-deploy.yml

# Edit to customize for your needs
# - Update environment names
# - Adjust terraform-version if needed
# - Customize azure-region
# - Update paths filter if needed
```

## Deployment Process

### Pull Request Flow

When you create a pull request:

1. **Automatic validation** runs:
   - ✅ Terraform format check (`terraform fmt`)
   - ✅ Terraform validation (`terraform validate`)
   - ✅ TFLint code quality checks
   - ✅ Checkov security scanning

2. **Plan generation**:
   - 📊 Terraform plan is generated
   - 💬 Plan output is posted as a PR comment
   - 📦 Plan is saved as an artifact (30-day retention)

3. **Review the plan**:
   - Review the plan output in the PR comment
   - Address any validation or security issues
   - Get code review approval from team

4. **Merge the PR**:
   - Once approved, merge to `main` branch
   - This triggers the deployment flow

### Deployment Flow

When code is merged to `main`:

1. **Re-validation** (same as PR checks)
2. **Security scanning** (Checkov with fail-fast)
3. **Plan generation** (creates fresh plan for deployment)
4. **Manual approval required**:
   - Workflow pauses at the `apply` job
   - Designated approvers receive notification
   - Reviewer can see plan output and approve/reject
5. **Apply** (if approved):
   - Terraform applies the saved plan
   - Infrastructure is deployed to Azure
   - Outputs are saved as artifacts

### Manual Deployment

For emergency deployments or testing:

1. Navigate to: **Actions → Example Azure Terraform Deployment**
2. Click **Run workflow**
3. Select:
   - Branch: Usually `main`
   - Environment: `production`, `staging`, or `development`
4. Click **Run workflow**
5. Follow the same approval process

## Workflow Inputs & Customization

### Available Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (production, staging, development) |
| `terraform-version` | No | `1.9.0` | Terraform version to use |
| `working-directory` | No | `terraform` | Directory containing Terraform code |
| `azure-region` | No | `uksouth` | Azure region for deployment |

### Customizing the Child Workflow

Edit `.github/workflows/terraform-deploy.yml`:

```yaml
jobs:
  deploy:
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: 'production'           # Change environment
      terraform-version: '1.10.0'         # Update Terraform version
      working-directory: 'infrastructure' # Change directory
      azure-region: 'westeurope'          # Change region
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Security Features

### Built-in Security

- ✅ **No stored credentials**: OIDC authentication eliminates long-lived credentials
- ✅ **Pinned action versions**: All actions use major version pinning (e.g., `@v4`)
- ✅ **Security scanning**: Checkov scans for misconfigurations (fails on violations)
- ✅ **Code quality**: TFLint checks for best practices
- ✅ **Manual approval**: Human oversight required for all deployments
- ✅ **Plan verification**: Saved plan prevents drift between plan and apply
- ✅ **Audit trail**: Environment protection logs all approvals

### Permissions Model

The workflow uses minimal required permissions:

```yaml
permissions:
  contents: read         # Read repository code
  pull-requests: write   # Comment on PRs
  id-token: write        # Generate OIDC token
  issues: write          # Comment on issues
```

## Monitoring & Artifacts

### Workflow Artifacts

The workflow generates several artifacts (retained for 30 days):

1. **Checkov Report** (`checkov-report`):
   - Security scan results in JUnit XML format
   - Download from: Actions → Workflow run → Artifacts

2. **Terraform Plan** (`terraform-plan-{environment}`):
   - Binary plan file (`tfplan`)
   - Human-readable plan output (`plan.txt`)
   - Used by apply job to ensure consistency

3. **Terraform Outputs** (`terraform-outputs-{environment}`):
   - JSON file with all Terraform outputs
   - Useful for downstream automation

### Viewing Workflow Runs

1. Navigate to: **Actions** tab
2. Select workflow: **Example Azure Terraform Deployment**
3. Click on a specific run to see:
   - Job status and logs
   - Validation results
   - Security scan findings
   - Plan output
   - Deployment results

### PR Comments

The workflow automatically comments on pull requests with:

- ✅ Validation results (format, validate, TFLint)
- 📊 Terraform plan output (collapsed in details section)
- ℹ️ Metadata (pusher, action type, workflow name)

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

## Rollback Procedures

See [ROLLBACK.md](./ROLLBACK.md) for emergency rollback instructions.

## Support

For issues with:

- **This workflow**: Open an issue in your repository
- **Parent workflow**: Contact the platform team or open an issue in `nathlan/.github-workflows`
- **Azure permissions**: Contact your Azure administrators
- **Terraform code**: Review Terraform documentation or consult your team

## Estimated Setup Time

- **Azure setup**: 30-45 minutes
- **GitHub configuration**: 15-20 minutes
- **Terraform backend**: 20-30 minutes
- **Testing**: 15-30 minutes

**Total**: Approximately 1.5-2 hours for initial setup

## Next Steps

1. ✅ Complete Azure OIDC setup
2. ✅ Configure GitHub secrets
3. ✅ Create environment protection rules
4. ✅ Configure Terraform backend
5. ✅ Copy and customize child workflow
6. ✅ Create test PR to validate setup
7. ✅ Perform first deployment with approval
8. ✅ Document team-specific procedures

---

**Ready to deploy?** Create your first PR and watch the automation in action! 🚀
