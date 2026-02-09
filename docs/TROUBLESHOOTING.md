# Troubleshooting Guide

## Overview

This guide helps you diagnose and resolve common issues with the Azure Terraform CI/CD workflow.

## Quick Diagnostic Commands

```bash
# Check workflow status
gh run list --workflow=example-azure-terraform-child.yml

# View latest workflow run
gh run view

# View logs for specific job
gh run view --job=<job-id> --log

# Check Azure authentication
az account show

# Validate Terraform locally
cd terraform/
terraform init
terraform validate
terraform plan
```

## Common Issues

### 1. OIDC Authentication Failures

#### Error Message:
```
Error: Azure authentication failed
Unable to exchange OIDC token for Azure access token
```

#### Possible Causes:
- Federated credential not configured correctly
- Wrong repository or branch specified in federated credential
- Secrets not configured in GitHub

#### Solutions:

**A. Verify Federated Credentials**:

```bash
# List federated credentials
APP_ID="your-app-id"
az ad app federated-credential list --id ${APP_ID}

# Check the subject matches your repository
# Should be: repo:OWNER/REPO:ref:refs/heads/main
```

**B. Verify GitHub Secrets**:
- Go to: Settings → Secrets and variables → Actions
- Ensure these secrets exist:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
- Values should match Azure App Registration

**C. Check Federated Credential Configuration**:

Create/update federated credential:
```bash
REPO_ORG="your-org"
REPO_NAME="your-repo"
OBJECT_ID=$(az ad app show --id ${APP_ID} --query id -o tsv)

# For main branch
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --body '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'${REPO_ORG}'/'${REPO_NAME}':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For pull requests
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --body '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'${REPO_ORG}'/'${REPO_NAME}':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**D. Verify Repository ID Token Permissions**:

Ensure workflow has `id-token: write` permission:
```yaml
permissions:
  id-token: write
  contents: read
```

#### Verification:
```bash
# Test OIDC login manually (requires gh CLI)
gh auth status

# Or test with Azure CLI
az login --service-principal \
  --username ${AZURE_CLIENT_ID} \
  --tenant ${AZURE_TENANT_ID} \
  --federated-token "$(curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r .value)"
```

---

### 2. Terraform Backend Initialization Failures

#### Error Message:
```
Error: Failed to get existing workspaces
Error: Backend initialization failed
```

#### Possible Causes:
- Storage account doesn't exist
- Insufficient permissions on storage account
- `use_oidc` not set in backend configuration
- Network connectivity issues

#### Solutions:

**A. Verify Storage Account Exists**:
```bash
STORAGE_ACCOUNT="tfstate12345"
RESOURCE_GROUP="terraform-state-rg"

az storage account show \
  --name ${STORAGE_ACCOUNT} \
  --resource-group ${RESOURCE_GROUP}
```

**B. Check Permissions**:
```bash
# Service principal should have Storage Blob Data Contributor role
az role assignment list \
  --assignee ${AZURE_CLIENT_ID} \
  --scope "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"

# If missing, add role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee ${AZURE_CLIENT_ID} \
  --scope "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"
```

**C. Verify Backend Configuration**:

Check `terraform/terraform.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
    use_oidc            = true  # ← Must be true!
  }
}
```

**D. Test Backend Access Locally**:
```bash
cd terraform/

# Login with OIDC (if testing locally)
az login

# Initialize backend
terraform init
```

#### Verification:
```bash
# Check if state file exists
az storage blob list \
  --account-name ${STORAGE_ACCOUNT} \
  --container-name tfstate \
  --auth-mode login
```

---

### 3. Checkov Security Scan Failures

#### Error Message:
```
Error: Checkov found security violations
Check: CKV_AZURE_XXX failed
```

#### Possible Causes:
- Security misconfiguration in Terraform code
- Policy violations
- Unintentional security risks

#### Solutions:

**A. Review Checkov Report**:
- Download artifact: `checkov-report` from workflow run
- Review specific violations
- Understand which resources are affected

**B. Common Violations and Fixes**:

**Storage Account without HTTPS**:
```hcl
# ❌ Bad
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  enable_https_traffic_only = false  # Violation
}

# ✅ Good
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  enable_https_traffic_only = true
}
```

**Missing Encryption**:
```hcl
# ❌ Bad
resource "azurerm_storage_account" "example" {
  # Missing encryption configuration
}

# ✅ Good
resource "azurerm_storage_account" "example" {
  name = "mystorageaccount"

  encryption {
    services {
      blob {
        enabled = true
      }
    }
  }
}
```

**Network Security Group Too Permissive**:
```hcl
# ❌ Bad
resource "azurerm_network_security_rule" "example" {
  name                        = "allow-all"
  source_address_prefix       = "*"
  destination_port_range      = "*"
  access                      = "Allow"
}

# ✅ Good
resource "azurerm_network_security_rule" "example" {
  name                        = "allow-specific"
  source_address_prefix       = "10.0.0.0/16"
  destination_port_range      = "443"
  access                      = "Allow"
}
```

**C. Suppress False Positives** (use sparingly):

Add inline comment:
```hcl
resource "azurerm_storage_account" "example" {
  name = "mystorageaccount"

  # checkov:skip=CKV_AZURE_33:Reason for exception
  public_network_access_enabled = true
}
```

Or configure `.checkov.yml`:
```yaml
skip-check:
  - CKV_AZURE_33  # Only if you have a valid business reason
```

**D. Run Checkov Locally**:
```bash
# Install checkov
pip install checkov

# Run scan
cd terraform/
checkov --directory . --framework terraform
```

#### Verification:
```bash
# Run locally and ensure no failures
checkov --directory terraform/ --framework terraform
```

---

### 4. Terraform Plan Shows Unexpected Changes

#### Error Message:
```
Plan shows resources being destroyed or recreated unexpectedly
```

#### Possible Causes:
- State drift (manual changes in Azure)
- Incorrect configuration
- Renamed resources
- Changed immutable properties

#### Solutions:

**A. Check for Manual Changes**:
```bash
# Refresh state to see actual Azure state
cd terraform/
terraform init
terraform refresh
terraform plan

# Compare with expected
git diff
```

**B. Review Specific Resource Changes**:
```bash
# Show detailed plan
terraform plan -no-color | tee plan.txt

# Focus on specific resource
terraform plan -target=azurerm_resource_group.example
```

**C. Import Manually Created Resources**:

If resource exists in Azure but not in state:
```bash
# Find resource ID in Azure
az resource show \
  --resource-group my-rg \
  --name my-vm \
  --resource-type "Microsoft.Compute/virtualMachines" \
  --query id -o tsv

# Import into Terraform state
terraform import azurerm_virtual_machine.example \
  "/subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/my-vm"
```

**D. Understand Resource Recreation**:

Some property changes force recreation:
```hcl
# These properties typically force recreation:
# - name
# - location
# - sku (often)
# - tier (often)

# Check Terraform docs for specific resource
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
```

#### Verification:
```bash
# Ensure plan matches expectations
terraform plan -out=tfplan
terraform show tfplan
```

---

### 5. Environment Protection / Approval Not Working

#### Error Message:
```
Workflow stuck waiting for approval
Approval button not showing
```

#### Possible Causes:
- Environment not configured
- User not in reviewers list
- Environment name mismatch
- Branch protection rules blocking

#### Solutions:

**A. Verify Environment Configuration**:
- Go to: Settings → Environments
- Check environment name matches workflow input (e.g., `production`)
- Verify "Required reviewers" is configured
- Check deployment branches allow `main`

**B. Check User Permissions**:
- Reviewers must have Write access to repository
- Verify user is in reviewers list
- Org owners can approve by default

**C. Verify Workflow Configuration**:
```yaml
# In child workflow
jobs:
  deploy:
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: 'production'  # ← Must match Settings → Environments
```

**D. Check Run Conditions**:

Apply job only runs on main branch:
```yaml
# In parent workflow
apply:
  if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
  environment: ${{ inputs.environment }}
```

#### Verification:
- Check Actions tab → Workflow run → Apply job shows "Waiting for approval"
- Approvers should receive email notification
- Approval button should appear in workflow run

---

### 6. Artifact Upload/Download Failures

#### Error Message:
```
Error: Unable to upload artifact
Error: Artifact not found
```

#### Possible Causes:
- Artifact name mismatch
- Path doesn't exist
- Permissions issue
- Artifact expired (>30 days)

#### Solutions:

**A. Verify Artifact Names Match**:

Upload in `plan` job:
```yaml
- name: Save Plan Artifact
  uses: actions/upload-artifact@v4
  with:
    name: terraform-plan-${{ inputs.environment }}  # ← Note the name
    path: ${{ inputs.working-directory }}/tfplan
```

Download in `apply` job:
```yaml
- name: Download Plan Artifact
  uses: actions/download-artifact@v4
  with:
    name: terraform-plan-${{ inputs.environment }}  # ← Must match
    path: ${{ inputs.working-directory }}
```

**B. Verify Paths Exist**:
```bash
# In workflow, check file exists before upload
- name: Verify Plan Exists
  run: |
    ls -la terraform/
    test -f terraform/tfplan || (echo "Plan file missing" && exit 1)
```

**C. Check Artifact Retention**:
- Artifacts expire after 30 days
- Re-run workflow if needed

**D. Check Permissions**:
```yaml
# Workflow needs these permissions
permissions:
  contents: read
  actions: read  # For artifacts
```

#### Verification:
```bash
# Download artifact locally to verify
gh run view <run-id>
gh run download <run-id> --name terraform-plan-production
```

---

### 7. TFLint Failures

#### Error Message:
```
Error: TFLint found issues
```

#### Possible Causes:
- Code quality issues
- Deprecated syntax
- Best practice violations
- Module configuration problems

#### Solutions:

**A. Run TFLint Locally**:
```bash
# Install TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Initialize
cd terraform/
tflint --init

# Run lint
tflint
```

**B. Common Issues and Fixes**:

**Deprecated Resource**:
```hcl
# ❌ Bad - using deprecated resource
resource "azurerm_virtual_machine" "example" {
  # ...
}

# ✅ Good - use new resource
resource "azurerm_linux_virtual_machine" "example" {
  # ...
}
```

**Invalid Instance Type**:
```hcl
# ❌ Bad - typo in SKU
resource "azurerm_virtual_machine" "example" {
  vm_size = "Standard_D2_v3"  # Wrong format
}

# ✅ Good - correct SKU
resource "azurerm_linux_virtual_machine" "example" {
  size = "Standard_D2s_v3"
}
```

**C. Configure TFLint Rules**:

Create `.tflint.hcl`:
```hcl
plugin "azurerm" {
  enabled = true
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}
```

#### Verification:
```bash
# Run locally and fix all issues
cd terraform/
tflint
```

---

### 8. Workflow Not Triggering

#### Symptoms:
- Push to main doesn't trigger workflow
- PR doesn't trigger workflow
- Workflow_dispatch button missing

#### Possible Causes:
- Incorrect path filter
- Branch name mismatch
- Syntax error in workflow file
- Workflow disabled

#### Solutions:

**A. Check Path Filters**:
```yaml
on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'  # Only triggers if terraform/ files change
```

**B. Verify Branch Name**:
```bash
# Check current branch name
git branch --show-current

# Workflow may expect 'main' but repo uses 'master'
```

**C. Validate Workflow Syntax**:
```bash
# Install actionlint
brew install actionlint  # macOS
# or
sudo snap install actionlint  # Linux

# Validate workflow
actionlint .github/workflows/example-azure-terraform-child.yml
```

**D. Check if Workflow is Disabled**:
- Go to: Actions → Workflows
- Look for disabled badge
- Enable if needed

**E. Verify File is in Correct Location**:
```bash
# Must be in .github/workflows/ directory
ls -la .github/workflows/
```

#### Verification:
```bash
# Create test commit
git commit --allow-empty -m "Test workflow trigger"
git push origin main

# Check if workflow runs
gh run list --workflow=example-azure-terraform-child.yml
```

---

### 9. Parallel Workflow Runs Conflict

#### Error Message:
```
Error: Error acquiring the state lock
Lock Info:
  ID: xxxxx
  Path: production.terraform.tfstate
```

#### Possible Causes:
- Multiple workflows running simultaneously
- Previous workflow didn't release lock
- Manual Terraform run in progress

#### Solutions:

**A. Wait for Other Run to Complete**:
- Check Actions tab for running workflows
- Wait for completion or cancel other run

**B. Configure Concurrency Control**:

Add to child workflow:
```yaml
concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false  # Don't cancel, just queue
```

**C. Force Unlock** (if lock is stale):
```bash
# Get lock ID from error message
cd terraform/
terraform force-unlock <lock-id>

# Use with extreme caution!
```

**D. Prevent Parallel PRs from Applying**:

Parent workflow already has this:
```yaml
apply:
  if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
```

#### Verification:
```bash
# Check state lock status
terraform init
terraform plan  # Should complete without lock error
```

---

## Debugging Techniques

### Enable Debug Logging

Add these secrets to your repository:

- `ACTIONS_RUNNER_DEBUG`: `true`
- `ACTIONS_STEP_DEBUG`: `true`

This enables verbose logging for all workflow runs.

### Local Testing

Test workflow components locally:

```bash
# 1. Test Terraform locally
cd terraform/
terraform init
terraform validate
terraform fmt -check
terraform plan

# 2. Test Checkov locally
checkov --directory terraform/ --framework terraform

# 3. Test TFLint locally
cd terraform/
tflint --init
tflint

# 4. Test Azure authentication
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID
az account show
```

### Workflow Simulation with Act

Use [act](https://github.com/nektos/act) to run workflows locally:

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act -j validate  # Run validate job only
act push         # Simulate push event
```

### GitHub CLI Debugging

```bash
# View workflow runs
gh run list

# Watch workflow run in real-time
gh run watch

# View specific job logs
gh run view --job=123456 --log

# View workflow definition
gh workflow view example-azure-terraform-child.yml

# Re-run failed jobs
gh run rerun <run-id> --failed
```

---

## Performance Issues

### Slow Workflow Runs

**Symptoms**: Workflows taking longer than expected

**Solutions**:

1. **Cache Terraform Plugins**:
```yaml
- name: Cache Terraform Plugins
  uses: actions/cache@v4
  with:
    path: ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
```

2. **Reduce Checkov Scope** (if needed):
```yaml
- name: Run Checkov
  run: |
    checkov --directory terraform/ \
      --skip-check CKV_DOCKER_* \  # Skip Docker checks if not using containers
      --compact  # Less verbose output
```

3. **Use Terraform Parallelism**:
```yaml
- name: Terraform Apply
  run: terraform apply -auto-approve -parallelism=20 tfplan
```

### Large Plan Output

**Symptoms**: PR comments truncated, artifacts too large

**Solutions**:

1. **Truncate plan in comment** (already implemented):
```yaml
const maxLength = 65000;
const truncatedPlan = plan.length > maxLength
  ? plan.substring(0, maxLength) + '\n\n... (truncated)'
  : plan;
```

2. **Link to artifact instead of full output**:
```yaml
The plan is too large to display. Download the artifact to view.
```

---

## Getting Additional Help

### Resources

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm
- **Checkov Docs**: https://www.checkov.io/
- **TFLint Docs**: https://github.com/terraform-linters/tflint
- **Azure OIDC Setup**: https://docs.microsoft.com/azure/developer/github/connect-from-azure

### Support Channels

1. **Platform Team**: [Add your team's contact]
2. **GitHub Issues**: Open issue in `nathlan/.github-workflows` for parent workflow problems
3. **Team Slack**: [Add your team's Slack channel]
4. **Azure Support**: For Azure-specific issues

### Creating a Support Request

When requesting help, include:

1. **Workflow run URL**: Link to failing workflow
2. **Error message**: Copy exact error text
3. **Steps to reproduce**: What triggered the failure
4. **Recent changes**: What was changed before failure
5. **Environment**: Which environment (prod/staging/dev)
6. **Logs**: Download and attach workflow logs
7. **Plan output**: If available, attach plan artifact

### Template for Support Request

```markdown
**Issue Summary**: Brief description

**Workflow Run**: https://github.com/org/repo/actions/runs/123456

**Error Message**:
```
<paste error here>
```

**Steps to Reproduce**:
1. Step 1
2. Step 2

**Recent Changes**:
- PR #123 merged yesterday
- Updated azurerm_resource_group configuration

**Environment**: production

**Attachments**:
- workflow-logs.txt
- plan-output.txt
```

---

**Still stuck?** Don't hesitate to reach out to the platform team. We're here to help! 🚀
