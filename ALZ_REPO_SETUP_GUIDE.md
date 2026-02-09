# ALZ Infrastructure Repositories - Setup Guide

**Status:** ✅ Repository Structure Prepared | ✅ Reusable Workflows Available | ⏳ Awaiting Repository Creation

**NEW:** The reusable Azure Terraform workflow has been created and is ready to deploy to the `.github-workflows` repository!

This guide documents the complete repository setup required for the ALZ vending orchestrator. All necessary files have been prepared in `/tmp/alz-subscriptions-setup/` and the reusable workflow is available in `.github/workflows/azure-terraform-deploy-reusable.yml`.

---

## Overview

The ALZ vending orchestrator requires two infrastructure repositories:

1. **`nathlan/alz-subscriptions`** (CRITICAL) - Core subscription vending infrastructure
2. **`nathlan/.github-workflows`** (HIGH PRIORITY) - Reusable GitHub Actions workflows

This guide provides multiple methods to create and populate these repositories.

---

## Repository 1: alz-subscriptions (CRITICAL)

### Purpose

Core repository for Azure Landing Zone subscription provisioning using Terraform. Contains:
- Landing zone `.tfvars` files (one per subscription)
- Terraform root module calling `terraform-azurerm-landing-zone-vending`
- GitHub Actions CI/CD workflows (plan on PR, apply on merge)

### Prepared Files

Complete repository structure has been prepared in `/tmp/alz-subscriptions-setup/`:

```
/tmp/alz-subscriptions-setup/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml          # Runs on PR, plans changes
│       └── terraform-apply.yml         # Runs on merge, applies changes
├── landing-zones/
│   ├── example-app-prod.tfvars        # Example: Production app workload
│   └── example-api-dev.tfvars         # Example: Dev/test API workload
├── .gitignore                         # Terraform ignores
├── .terraform-version                 # Pins Terraform to 1.9.0
├── README.md                          # Complete documentation
├── backend.tf                         # Azure Storage backend
├── main.tf                            # Calls LZ vending module v1.1.0
├── outputs.tf                         # Module outputs
├── terraform.tfvars.example           # Template for new landing zones
└── variables.tf                       # Input variable definitions
```

**Total:** 12 files ready to push

### Method 1: Using GitHub CLI (Recommended)

```bash
# 1. Create repository
gh repo create nathlan/alz-subscriptions \
  --internal \
  --description "Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform)" \
  --enable-issues \
  --enable-wiki=false

# 2. Clone and populate
cd /tmp
git clone https://github.com/nathlan/alz-subscriptions.git
cd alz-subscriptions

# 3. Copy prepared files
cp -r /tmp/alz-subscriptions-setup/* .
cp -r /tmp/alz-subscriptions-setup/.github .
cp /tmp/alz-subscriptions-setup/.gitignore .
cp /tmp/alz-subscriptions-setup/.terraform-version .

# 4. Initial commit and push
git add .
git commit -m "Initial commit: ALZ subscription vending infrastructure

- Terraform root module calling terraform-azurerm-landing-zone-vending v1.1.0
- GitHub Actions workflows for plan/apply
- Example landing zones (app-prod, api-dev)
- Complete documentation and configuration"
git push origin main

# 5. Configure repository settings
gh repo edit nathlan/alz-subscriptions \
  --enable-squash-merge \
  --disable-merge-commit \
  --enable-rebase-merge \
  --delete-branch-on-merge

# 6. Add topics
gh repo edit nathlan/alz-subscriptions \
  --add-topic azure \
  --add-topic landing-zone \
  --add-topic terraform \
  --add-topic infrastructure-as-code

# 7. Set up branch protection (requires admin permissions)
gh api \
  -X PUT \
  /repos/nathlan/alz-subscriptions/branches/main/protection \
  -f required_status_checks='{"strict":true,"contexts":["plan"]}' \
  -f enforce_admins=false \
  -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  -f restrictions=null
```

### Method 2: Using GitHub Web UI

1. **Create Repository:**
   - Go to https://github.com/organizations/nathlan/repositories/new
   - Repository name: `alz-subscriptions`
   - Description: "Azure Landing Zone subscription provisioning using Infrastructure as Code (Terraform)"
   - Visibility: Internal
   - Initialize: ❌ Do NOT initialize with README (we have prepared files)
   - Click "Create repository"

2. **Push Prepared Files:**
   ```bash
   cd /tmp/alz-subscriptions-setup
   git init
   git add .
   git commit -m "Initial commit: ALZ subscription vending infrastructure"
   git branch -M main
   git remote add origin https://github.com/nathlan/alz-subscriptions.git
   git push -u origin main
   ```

3. **Configure Settings:**
   - Go to Settings → General
     - Pull Requests: ✅ Allow squash merging, ✅ Allow rebase merging, ❌ Allow merge commits
     - ✅ Automatically delete head branches
   - Go to Settings → Topics
     - Add: `azure`, `landing-zone`, `terraform`, `infrastructure-as-code`

4. **Set Up Branch Protection:**
   - Go to Settings → Branches → Add rule
   - Branch name pattern: `main`
   - ✅ Require a pull request before merging
     - Required approvals: 1
     - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
     - Add: `plan` (will appear after first workflow run)
   - Save changes

### Method 3: Using GitHub API with curl

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_personal_access_token_here"

# 1. Create repository
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/nathlan/repos \
  -d '{
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
    "delete_branch_on_merge": true
  }'

# 2. Then follow Method 2 steps 2-4 to push files and configure
```

### Required Secrets

After creating the repository, configure these secrets in Settings → Secrets and variables → Actions:

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AZURE_CLIENT_ID` | Service principal client ID | From Azure App Registration for OIDC |
| `AZURE_TENANT_ID` | Azure tenant ID | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | Management subscription ID | `az account show --query id -o tsv` |

### Required Environment

Create environment in Settings → Environments:

- **Name:** `azure-landing-zones`
- **Protection rules:**
  - ✅ Required reviewers (select platform team members)
  - Environment secrets: (same as repository secrets above)

### Verification

After setup, verify the repository:

```bash
# Check repository exists and is configured
gh repo view nathlan/alz-subscriptions

# Check files are present
gh api /repos/nathlan/alz-subscriptions/contents | jq -r '.[].name'

# Expected output:
# .github
# .gitignore
# .terraform-version
# README.md
# backend.tf
# landing-zones
# main.tf
# outputs.tf
# terraform.tfvars.example
# variables.tf
```

---

## Repository 2: .github-workflows (HIGH PRIORITY)

### Purpose

Reusable GitHub Actions workflows for Terraform deployments. Provides consistent CI/CD patterns across all workload repositories.

### ✅ NEW: Workflows Ready!

The reusable Azure Terraform workflow has been created by the CI/CD workflow agent and merged to the main branch!

**Available workflow:**
- `azure-terraform-deploy-reusable.yml` - Complete reusable workflow for Azure Terraform deployments

**Location in this repo:**
`.github/workflows/azure-terraform-deploy-reusable.yml`

### Required Repository Structure

```
nathlan/.github-workflows/
├── .github/
│   └── workflows/
│       └── azure-terraform-deploy.yml      # Reusable Azure workflow (from this repo)
└── README.md                               # Workflow documentation
```

### Quick Setup - Method 1: Using Prepared Workflow

```bash
# 1. Create repository
gh repo create nathlan/.github-workflows \
  --internal \
  --description "Reusable GitHub Actions workflows for Terraform deployments" \
  --enable-issues \
  --enable-wiki=false

# 2. Clone and set up
cd /tmp
git clone https://github.com/nathlan/.github-workflows.git
cd .github-workflows

# 3. Create directory structure
mkdir -p .github/workflows

# 4. Copy the reusable workflow from this repo
# Note: You'll need to copy from the .github-private repo
cp /path/to/.github-private/.github/workflows/azure-terraform-deploy-reusable.yml \
   .github/workflows/azure-terraform-deploy.yml

# 5. Create README
cat > README.md << 'EOF'
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
- Azure OIDC authentication (no stored credentials)
- Security scanning with Checkov (fails on violations)
- TFLint validation
- Plan artifact reuse (prevents drift)
- Environment protection with approvals
- Comprehensive PR comments

## Documentation

For detailed usage instructions, see the workflow file comments and the example-azure-terraform-child.yml in the .github-private repository.
EOF

# 6. Commit and push
git add .
git commit -m "Initial commit: Add reusable Azure Terraform workflow

- Copied azure-terraform-deploy-reusable.yml from .github-private repo
- Renamed to azure-terraform-deploy.yml for use as reusable workflow
- Added README with usage documentation"
git push origin main
```

### Quick Setup - Method 2: Direct File Creation

If you're setting this up through the GitHub UI or prefer to manually create files:

1. Create the repository `nathlan/.github-workflows` (internal visibility)
2. Create directory `.github/workflows/`
3. Copy content from `.github-private/.github/workflows/azure-terraform-deploy-reusable.yml`
4. Save as `.github/workflows/azure-terraform-deploy.yml` in the new repo
5. Commit to main branch

### Validation

After setup, verify the workflow is callable:

```bash
# From any repository, reference it in a workflow:
uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
```

---

## Post-Setup Validation

### For alz-subscriptions

```bash
# 1. Verify repository structure
gh repo view nathlan/alz-subscriptions

# 2. Verify workflows are present
gh workflow list --repo nathlan/alz-subscriptions

# Expected:
# Terraform Apply    active  1234567
# Terraform Plan     active  1234568

# 3. Test workflow (optional)
# Create a test PR with a modified example tfvars file
# Verify terraform-plan workflow runs successfully
```

### For .github-workflows

```bash
# 1. Verify repository exists
gh repo view nathlan/.github-workflows

# 2. Verify reusable workflows are present
gh api /repos/nathlan/.github-workflows/contents/.github/workflows | jq -r '.[].name'

# Expected:
# azure-terraform-deploy.yml
# github-terraform-deploy.yml
```

---

## Integration with ALZ Vending Agent

Once both repositories are created and populated:

### Step 1: Update ALZ Agent Configuration

The agent configuration file already references these repositories correctly:

```yaml
# In agents/alz-vending.agent.md
alz_infra_repo: "alz-subscriptions"          # ✅ Ready
reusable_workflow_repo: ".github-workflows"  # ⏳ Pending creation
```

No changes needed to the agent configuration.

### Step 2: Configure Azure Environment Values

Update the PLACEHOLDER values in `agents/alz-vending.agent.md` lines 433-437:

```bash
# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "tenant_id: \"$TENANT_ID\""

# Get billing scope (Enterprise Agreement)
BILLING_SCOPE=$(az billing enrollment-account list --query "[0].id" -o tsv)
echo "billing_scope: \"$BILLING_SCOPE\""

# Get hub network resource ID
HUB_VNET_ID=$(az network vnet show \
  --resource-group rg-hub-network \
  --name vnet-hub-uksouth \
  --query id -o tsv)
echo "hub_network_resource_id: \"$HUB_VNET_ID\""
```

Update the agent file with these real values.

### Step 3: Test ALZ Orchestrator

With both repositories created and Azure values configured, test the orchestrator:

```
@alz-vending

workload_name: test-workload
environment: DevTest
location: uksouth
team_name: platform-engineering
address_space: 10.200.0.0/24
cost_center: TEST-001
workload_description: Test workload for ALZ orchestrator validation
```

---

## Troubleshooting

### Repository Creation Fails

**Error:** "Repository already exists"
**Solution:** Check if repo was partially created: `gh repo view nathlan/alz-subscriptions`

**Error:** "Insufficient permissions"
**Solution:** Ensure you have admin access to the nathlan organization

### Push Fails

**Error:** "Permission denied"
**Solution:** Verify your GitHub authentication: `gh auth status`

**Error:** "Protected branch"
**Solution:** Branch protection may be enabled by default. Use a PR or temporarily disable protection.

### Workflow Failures

**Error:** "Secret not found"
**Solution:** Verify all required secrets are configured in repository settings

**Error:** "Azure login failed"
**Solution:** Verify OIDC federation is set up correctly in Azure App Registration

---

## Summary

### What's Prepared

- ✅ Complete `alz-subscriptions` repository structure (12 files)
- ✅ Terraform configuration calling LZ vending module v1.1.0
- ✅ GitHub Actions workflows (plan on PR, apply on merge)
- ✅ Example landing zones (prod and dev)
- ✅ Complete documentation
- ✅ **NEW:** Reusable Azure Terraform workflow ready for `.github-workflows` repo

### What's Needed

1. **Create `nathlan/alz-subscriptions` repository** (use Method 1, 2, or 3 above)
2. **Push prepared files from `/tmp/alz-subscriptions-setup/`**
3. **Create `nathlan/.github-workflows` repository** (use documented method with prepared workflow)
4. **Configure repository secrets** (Azure OIDC credentials)
5. **Set up branch protection** (require PR review, status checks)
6. **Update Azure configuration values** in `agents/alz-vending.agent.md`

### Time Estimates

- Repository creation and file push (alz-subscriptions): 10-15 minutes
- Repository creation and workflow deployment (.github-workflows): 10-15 minutes
- Secret and protection configuration: 10-15 minutes
- **Total:** 30-45 minutes for complete setup (faster with prepared workflow!)

---

**Files Location:** `/tmp/alz-subscriptions-setup/`
**Reusable Workflow:** `.github/workflows/azure-terraform-deploy-reusable.yml`
**Guide Created:** 2026-02-09
**Guide Updated:** 2026-02-09 (added reusable workflow instructions)
**Ready to Deploy:** ✅ Yes
