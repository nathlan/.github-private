# ALZ Infrastructure - Manual Configuration Guide

**Status:** ✅ Automated Setup Complete | ⚠️ Manual Configuration Required  
**Date:** 2026-02-10  
**For:** Platform Engineering Team

---

## Overview

The ALZ infrastructure repositories have been created and populated with automated tooling. However, some configuration tasks require manual setup due to GitHub MCP tool limitations or security restrictions.

This guide provides step-by-step instructions for completing the remaining manual configuration.

---

## ✅ What Has Been Completed (Automated)

### Repository Creation & File Population
- ✅ **nathlan/alz-subscriptions** - Created with 14 files
  - Terraform configuration (main.tf, variables.tf, outputs.tf, backend.tf)
  - GitHub Actions workflows (terraform-plan.yml, terraform-apply.yml)
  - Example landing zones (example-app-prod.tfvars, example-api-dev.tfvars)
  - Documentation and configuration files

- ✅ **nathlan/.github-workflows** - Created with 2 files
  - Reusable Azure Terraform deployment workflow
  - Complete documentation

- ✅ **nathlan/alz-workload-template** - Created with 7 files
  - Template workflow structure
  - Terraform directory with starter files

---

## ⚠️ Manual Configuration Required

The following tasks must be completed manually by the Platform Engineering team with appropriate GitHub and Azure permissions.

### Task 1: Configure Repository Secrets (alz-subscriptions)

**Why Manual:** GitHub MCP tools cannot create or modify repository secrets for security reasons.

**Prerequisites:**
- Admin access to `nathlan/alz-subscriptions` repository
- Azure service principal with OIDC configured for GitHub Actions

**Steps:**

1. **Navigate to Repository Secrets:**
   - Go to: https://github.com/nathlan/alz-subscriptions/settings/secrets/actions
   - Click "New repository secret"

2. **Add Required Secrets:**

   | Secret Name | Description | How to Obtain |
   |-------------|-------------|---------------|
   | `AZURE_CLIENT_ID` | Service principal application (client) ID | Azure Portal → App registrations → Your SP → Application (client) ID |
   | `AZURE_TENANT_ID` | Azure Active Directory tenant ID | Azure Portal → Azure Active Directory → Tenant ID |
   | `AZURE_SUBSCRIPTION_ID` | Management subscription ID | Azure Portal → Subscriptions → Your management subscription ID |

3. **Verify OIDC Configuration:**
   
   Ensure your Azure service principal has federated credentials configured for GitHub:
   
   ```bash
   # Verify federated credential exists
   az ad app federated-credential list \
     --id <YOUR_APP_ID> \
     --query "[?name=='github-alz-subscriptions']"
   ```
   
   If not configured, create it:
   
   ```bash
   az ad app federated-credential create \
     --id <YOUR_APP_ID> \
     --parameters '{
       "name": "github-alz-subscriptions",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:nathlan/alz-subscriptions:ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   
   # Add credential for pull requests
   az ad app federated-credential create \
     --id <YOUR_APP_ID> \
     --parameters '{
       "name": "github-alz-subscriptions-pr",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:nathlan/alz-subscriptions:pull_request",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

4. **Assign Azure Permissions:**
   
   The service principal needs appropriate permissions:
   
   ```bash
   # Assign Owner at management group level for subscription creation
   az role assignment create \
     --assignee <SERVICE_PRINCIPAL_OBJECT_ID> \
     --role "Owner" \
     --scope "/providers/Microsoft.Management/managementGroups/<MANAGEMENT_GROUP_ID>"
   ```

---

### Task 2: Create Environment with Approvals (alz-subscriptions)

**Why Manual:** GitHub MCP has limited support for environment configuration, especially approval requirements.

**Prerequisites:**
- Admin access to `nathlan/alz-subscriptions` repository
- List of required reviewers (platform team members)

**Steps:**

1. **Create Environment:**
   - Go to: https://github.com/nathlan/alz-subscriptions/settings/environments
   - Click "New environment"
   - Name: `azure-landing-zones`
   - Click "Configure environment"

2. **Configure Environment Protection Rules:**
   
   **Required Reviewers:**
   - ✅ Check "Required reviewers"
   - Add platform team members (minimum 1 required)
   - Suggested reviewers:
     - Platform engineering leads
     - Azure architects
     - Security team members

   **Deployment Branches:**
   - ✅ Select "Protected branches only"
   - This ensures only code from protected branches (main) can deploy

   **Wait Timer:**
   - Optional: Set wait timer (0-43,200 minutes)
   - Recommended: 0 minutes (immediate deployment after approval)

3. **Add Environment Secrets:**
   
   Add the same three secrets at environment level:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   
   **Note:** Environment-level secrets take precedence over repository secrets for environment-protected jobs.

4. **Save Configuration**

---

### Task 3: Set Up Branch Protection (alz-subscriptions)

**Why Manual:** GitHub MCP branch protection capabilities are limited.

**Prerequisites:**
- Admin access to `nathlan/alz-subscriptions` repository

**Steps:**

1. **Navigate to Branch Protection:**
   - Go to: https://github.com/nathlan/alz-subscriptions/settings/branches
   - Click "Add branch protection rule"

2. **Configure Protection for `main` Branch:**
   
   **Branch name pattern:** `main`
   
   **Protection Settings:**
   
   ✅ **Require a pull request before merging**
   - ✅ Require approvals: 1
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require review from Code Owners (if CODEOWNERS file added)
   
   ✅ **Require status checks to pass before merging**
   - ✅ Require branches to be up to date before merging
   - Required status checks (add after first workflow run):
     - `validate`
     - `security`
     - `plan`
   
   ✅ **Require conversation resolution before merging**
   
   ✅ **Require signed commits** (recommended but optional)
   
   ✅ **Include administrators** (recommended: unchecked for emergency access)
   
   ✅ **Restrict who can push to matching branches**
   - Add: `platform-engineering` team
   
   ✅ **Allow force pushes** - ❌ Disabled
   
   ✅ **Allow deletions** - ❌ Disabled

3. **Save Changes**

4. **Verify Protection:**
   
   Test by attempting to push directly to main (should be blocked):
   
   ```bash
   # This should fail
   git push origin main
   # Error: protected branch hook declined
   ```

---

### Task 4: Enable Template Flag (alz-workload-template)

**Why Manual:** GitHub MCP cannot set the `is_template` repository property.

**Prerequisites:**
- Admin access to `nathlan/alz-workload-template` repository

**Steps:**

1. **Navigate to Repository Settings:**
   - Go to: https://github.com/nathlan/alz-workload-template/settings

2. **Enable Template Repository:**
   - Scroll down to "Template repository" section
   - ✅ Check "Template repository"
   - Read the information about template repositories

3. **Save Changes:**
   - The "Use this template" button will now appear on the repository homepage

4. **Verify:**
   - Visit: https://github.com/nathlan/alz-workload-template
   - Confirm "Use this template" button is visible (green button near top-right)

---

### Task 5: Update Azure Configuration Values (agents/alz-vending.agent.md)

**Why Manual:** Requires Azure administrator to obtain real values.

**Prerequisites:**
- Azure CLI access with appropriate permissions
- Access to edit files in `nathlan/.github-private` repository

**Steps:**

1. **Obtain Azure Configuration Values:**
   
   ```bash
   # 1. Get Tenant ID
   TENANT_ID=$(az account show --query tenantId -o tsv)
   echo "Tenant ID: $TENANT_ID"
   
   # 2. Get Billing Scope (Enterprise Agreement example)
   BILLING_SCOPE=$(az billing enrollment-account list --query "[0].id" -o tsv)
   echo "Billing Scope: $BILLING_SCOPE"
   # Format: /providers/Microsoft.Billing/billingAccounts/{id}/enrollmentAccounts/{id}
   
   # 3. Get Hub VNet Resource ID
   HUB_VNET_ID=$(az network vnet show \
     --resource-group rg-hub-network \
     --name vnet-hub-uksouth \
     --query id -o tsv)
   echo "Hub VNet ID: $HUB_VNET_ID"
   # Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}
   ```

2. **Update Agent Configuration:**
   
   Edit `nathlan/.github-private/agents/alz-vending.agent.md`:
   
   Find lines 433-437 and replace PLACEHOLDER values:
   
   ```yaml
   # Before:
   tenant_id: "PLACEHOLDER"
   billing_scope: "PLACEHOLDER"
   hub_network_resource_id: "PLACEHOLDER"
   
   # After:
   tenant_id: "00000000-0000-0000-0000-000000000000"  # Your actual tenant ID
   billing_scope: "/providers/Microsoft.Billing/billingAccounts/xxxxx/enrollmentAccounts/xxxxx"
   hub_network_resource_id: "/subscriptions/xxxxx/resourceGroups/rg-hub-network/providers/Microsoft.Network/virtualNetworks/vnet-hub-uksouth"
   ```

3. **Commit and Push:**
   
   ```bash
   git add agents/alz-vending.agent.md
   git commit -m "config(alz): Update Azure configuration values"
   git push origin main
   ```

---

### Task 6: Update Example Landing Zone Files (Optional but Recommended)

**Why Manual:** Example files contain placeholder values that should be updated with real Azure values.

**Steps:**

1. **Navigate to Repository:**
   - Go to: https://github.com/nathlan/alz-subscriptions

2. **Edit Example Files:**
   
   Update placeholders in:
   - `landing-zones/example-app-prod.tfvars`
   - `landing-zones/example-api-dev.tfvars`
   
   Replace:
   - `PLACEHOLDER_BILLING_SCOPE` → Your actual billing scope
   - `PLACEHOLDER_HUB_VNET_ID` → Your actual hub VNet resource ID
   - `10.100.0.0/24` and `10.101.0.0/24` → Your allocated CIDR blocks

3. **Optional: Add CODEOWNERS File:**
   
   Create `.github/CODEOWNERS`:
   
   ```
   # ALZ Subscription Vending - Code Owners
   
   # Platform Engineering team owns all landing zone definitions
   /landing-zones/ @nathlan/platform-engineering
   
   # Terraform module configuration
   *.tf @nathlan/platform-engineering
   
   # GitHub Actions workflows
   /.github/workflows/ @nathlan/platform-engineering
   ```

---

## Verification Checklist

After completing all manual configuration tasks, verify the setup:

### alz-subscriptions Repository

- [ ] Repository secrets configured (3 secrets)
- [ ] Environment `azure-landing-zones` created with approvals
- [ ] Branch protection configured for `main` branch
- [ ] Example landing zone files have valid Azure values
- [ ] OIDC federated credentials configured in Azure

### alz-workload-template Repository

- [ ] Template repository flag enabled
- [ ] "Use this template" button visible on homepage

### Azure Configuration

- [ ] Service principal has appropriate permissions
- [ ] OIDC federated credentials exist for alz-subscriptions
- [ ] Billing scope identified and documented
- [ ] Hub VNet resource ID identified and documented
- [ ] Tenant ID documented

### Agent Configuration

- [ ] `agents/alz-vending.agent.md` updated with real Azure values
- [ ] No PLACEHOLDER values remain in configuration

---

## Testing the Setup

### Test 1: Workflow Execution

1. **Create a Test Branch:**
   ```bash
   git checkout -b test/workflow-validation
   ```

2. **Make a Minor Change:**
   ```bash
   echo "# Test" >> landing-zones/README.md
   git add landing-zones/README.md
   git commit -m "test: Validate workflow execution"
   git push origin test/workflow-validation
   ```

3. **Create Pull Request:**
   - Go to repository and create PR from `test/workflow-validation` to `main`
   - Verify `terraform-plan` workflow runs
   - Check for workflow execution errors
   - Verify PR comment with plan output appears

4. **Verify Status Checks:**
   - Confirm `validate`, `security`, and `plan` jobs complete
   - Review any errors or warnings

### Test 2: Environment Protection

1. **Merge Test PR:**
   - Get required approval(s)
   - Merge PR to `main`

2. **Verify Approval Gate:**
   - Go to Actions tab
   - Observe `terraform-apply` workflow waiting for environment approval
   - Approve deployment to `azure-landing-zones` environment
   - Verify workflow completes

### Test 3: ALZ Vending Orchestrator

Once all configuration is complete, test the ALZ vending orchestrator:

```
@alz-vending

workload_name: test-workload
environment: DevTest
location: uksouth
team_name: platform-engineering
address_space: 10.200.0.0/24
cost_center: TEST-001
```

**Expected Results:**
1. ✅ Phase 0: Input validation succeeds
2. ✅ Phase 1: Creates branch and PR in alz-subscriptions
3. ✅ Phase 2: Hands off to github-config agent
4. ✅ Phase 3: Hands off to cicd-workflow agent
5. ✅ Tracking issue created

---

## Troubleshooting

### Issue: Workflow fails with "Error: Azure Login Failed"

**Cause:** OIDC authentication not configured correctly

**Solution:**
1. Verify federated credentials exist in Azure
2. Check subject claim matches repository: `repo:nathlan/alz-subscriptions:ref:refs/heads/main`
3. Verify audience is: `api://AzureADTokenExchange`

### Issue: Status checks don't appear in branch protection

**Cause:** Status checks only appear after first workflow run

**Solution:**
1. Run workflows at least once
2. Return to branch protection settings
3. Status check names will now be available to select

### Issue: Environment approval not required

**Cause:** Environment protection not configured correctly

**Solution:**
1. Verify environment name in workflow matches created environment
2. Check "Required reviewers" is enabled
3. Ensure reviewers are added

### Issue: Can't push to main branch

**Cause:** Branch protection is working correctly

**Solution:**
1. This is expected behavior
2. Create a PR instead of pushing directly
3. Emergency: Admin can temporarily disable protection if needed

---

## Support

For questions or issues with manual configuration:

- **Platform Engineering Team:** Create issue in `nathlan/.github-private`
- **Azure Configuration:** Contact Azure administrators
- **GitHub Configuration:** Contact GitHub organization admins

---

## Related Documentation

- `ALZ_IMPLEMENTATION_INSTRUCTIONS.md` - Complete implementation guide
- `ALZ_DEPLOYMENT_QUICKSTART.md` - Quick reference guide  
- `ALZ_VENDING_DIAGNOSTICS.md` - Diagnostic information
- `agents/alz-vending.agent.md` - Orchestrator configuration

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-10  
**Status:** Ready for Platform Team Implementation

**Next Steps:**
1. Complete Task 1: Configure repository secrets
2. Complete Task 2: Create environment with approvals
3. Complete Task 3: Set up branch protection
4. Complete Task 4: Enable template flag
5. Complete Task 5: Update Azure configuration values
6. Run Test 1: Workflow execution
7. Run Test 2: Environment protection
8. Run Test 3: ALZ vending orchestrator
