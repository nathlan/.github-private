# ALZ Infrastructure Deployment - Quick Start

**Created:** 2026-02-09
**Status:** ✅ Ready to Deploy

## Overview

A GitHub Actions workflow has been created to automatically deploy the ALZ infrastructure repositories using the GitHub API. This provides a "non-read-only" solution for repository creation as requested.

## How to Deploy

### Step 1: Run the Workflow

1. Go to the **Actions** tab in this repository
2. Select **"Create ALZ Infrastructure Repositories"** from the workflows list
3. Click **"Run workflow"** button (top right)
4. Keep both options checked:
   - ✅ Create nathlan/alz-subscriptions repository
   - ✅ Create nathlan/.github-workflows repository
5. Click the green **"Run workflow"** button

### Step 2: Monitor Execution

The workflow will:
- Create both repositories using GitHub API
- Push initial files to each repository
- Provide a summary of created repositories

**Expected Duration:** 2-3 minutes

### Step 3: Verify Creation

Check that repositories exist:
- https://github.com/nathlan/alz-subscriptions
- https://github.com/nathlan/.github-workflows

## What Gets Created

### Repository 1: nathlan/alz-subscriptions

**Files:**
- `main.tf` - Terraform root module
- `variables.tf` - Input variables
- `outputs.tf` - Module outputs
- `backend.tf` - Azure Storage backend
- `README.md` - Documentation
- `.gitignore` - Terraform ignores
- `.terraform-version` - Version pin (1.9.0)
- `landing-zones/.gitkeep` - Directory placeholder

**Configuration:**
- Visibility: Internal
- Issues: Enabled
- Projects: Enabled
- Auto-delete branches: Enabled
- Squash merge: Enabled
- Merge commits: Disabled

### Repository 2: nathlan/.github-workflows

**Files:**
- `.github/workflows/azure-terraform-deploy.yml` - Reusable workflow
- `README.md` - Usage documentation

**Configuration:**
- Visibility: Internal
- Issues: Enabled

## Next Steps After Deployment

### 1. Configure Secrets in alz-subscriptions

Add these secrets in Settings → Secrets and variables → Actions:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

### 2. Create Environment in alz-subscriptions

Settings → Environments → New environment:
- Name: `azure-landing-zones`
- Add required reviewers (platform team)
- Add environment secrets (same as above)

### 3. Update Azure Configuration

Edit `agents/alz-vending.agent.md` lines 433-437 with real values:

```bash
# Get values
az account show --query tenantId -o tsv
az billing enrollment-account list --query "[0].id" -o tsv
az network vnet show --resource-group rg-hub-network --name vnet-hub-uksouth --query id -o tsv
```

### 4. Test the ALZ Orchestrator

Once repositories and configuration are complete, test with:

```
@alz-vending

workload_name: test-workload
environment: DevTest
location: uksouth
team_name: platform-engineering
address_space: 10.200.0.0/24
cost_center: TEST-001
```

## Troubleshooting

### Workflow Fails: "Permission denied"

**Issue:** GITHUB_TOKEN doesn't have org repo creation permissions

**Solution:**
- Repository admins may need to approve the workflow
- Or manually create repositories and use workflow to populate them

### Workflow Succeeds but Push Fails

**Issue:** Repository created but files not pushed

**Solution:**
- Go to the created repository
- Manually push files from local clone

### Repository Already Exists

**Issue:** Repository with same name already exists

**Solution:**
- Delete or rename existing repository
- Or modify workflow to use different names

## Technical Details

**Workflow File:** `.github/workflows/create-alz-infrastructure-repos.yml`

**Authentication:** Uses `GITHUB_TOKEN` provided by GitHub Actions

**API Endpoints:**
- `POST /orgs/nathlan/repos` - Create repository
- Push via HTTPS with token authentication

**Key Features:**
- Idempotent (can be re-run)
- Error handling for common issues
- Detailed logging and summary

## Alternative: Manual Deployment

If the workflow doesn't work due to permissions, follow the manual steps in `ALZ_REPO_SETUP_GUIDE.md`.

---

**Quick Reference:** Run workflow → Verify repos → Configure secrets → Update Azure values → Test orchestrator
