# Azure Terraform Workflows - Quick Reference Card

## 🎯 Workflow Pattern

```
Child Workflow (Your Repo)  →  Parent Workflow (Central)  →  Azure
terraform-deploy.yml            azure-terraform-deploy.yml     Infrastructure
```

## 📝 Workflow Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | ✅ | - | production, staging, development |
| `terraform-version` | ❌ | 1.9.0 | Terraform version |
| `working-directory` | ❌ | terraform | Terraform code location |
| `azure-region` | ❌ | uksouth | Azure region |

## 🔐 Required Secrets

- `AZURE_CLIENT_ID` - App Registration Client ID
- `AZURE_TENANT_ID` - Azure AD Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID

## 🔄 Workflow Jobs

```
validate → security → plan → apply
   ↓          ↓         ↓       ↓
  fmt      Checkov   artifact  approval
validate            PR comment  required
TFLint
```

## 🚦 Trigger Behavior

| Event | Validate | Security | Plan | Apply |
|-------|----------|----------|------|-------|
| Pull Request | ✅ | ✅ | ✅ | ❌ |
| Push to main | ✅ | ✅ | ✅ | ✅ (with approval) |
| Workflow Dispatch | ✅ | ✅ | ✅ | ✅ (with approval) |

## 📦 Artifacts (30-day retention)

1. **checkov-report** - Security scan results
2. **terraform-plan-{env}** - Plan file + text output
3. **terraform-outputs-{env}** - JSON outputs

## 🛠️ Quick Setup Commands

### Azure OIDC Setup
```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-terraform" \
  --role contributor --scopes "/subscriptions/${SUBSCRIPTION_ID}"

# Add federated credential (replace ORG/REPO)
OBJECT_ID=$(az ad app show --id ${APP_ID} --query id -o tsv)
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/${OBJECT_ID}/federatedIdentityCredentials" \
  --body '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:ORG/REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Storage Account for State
```bash
# Create state storage
az group create --name terraform-state-rg --location uksouth
az storage account create --name tfstate${RANDOM} \
  --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate \
  --account-name tfstate12345 --auth-mode login

# Enable versioning
az storage account blob-service-properties update \
  --account-name tfstate12345 --enable-versioning true
```

### Terraform Backend Config
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
    use_oidc            = true  # Critical!
  }
}

provider "azurerm" {
  features {}
  use_oidc = true  # Critical!
}
```

## 🎨 Child Workflow Template

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  pull_request:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:

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

## 🔍 Debugging Commands

```bash
# View workflow runs
gh run list --workflow=terraform-deploy.yml

# Watch current run
gh run watch

# View logs
gh run view --log

# Download artifacts
gh run download <run-id> --name terraform-plan-production

# Test Terraform locally
cd terraform/
terraform init
terraform validate
terraform plan
```

## 🚨 Emergency Rollback

### Method 1: Revert Commit (Recommended)
```bash
git revert <commit-sha>
git push origin rollback/revert-<commit-sha>
# Create PR, review plan, merge
```

### Method 2: Manual Resource Fix (Quick)
```bash
# Fix specific resource in Azure
az <command> update ...

# Sync state
cd terraform/
terraform refresh

# Update code
git revert <commit-sha>
```

## 📚 Documentation Links

- **Setup**: `docs/DEPLOYMENT.md`
- **Rollback**: `docs/ROLLBACK.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **Architecture**: `.github/workflows/README.md`

## ⚡ Common Issues

### OIDC Auth Failed
```bash
# Check federated credentials
az ad app federated-credential list --id ${APP_ID}

# Verify subject: repo:ORG/REPO:ref:refs/heads/main
```

### Backend Init Failed
```bash
# Check permissions
az role assignment list --assignee ${AZURE_CLIENT_ID}

# Verify use_oidc = true in backend config
```

### Checkov Failures
```bash
# Run locally
cd terraform/
checkov --directory . --framework terraform

# Fix violations or use skip-check (with reason)
```

## 🎯 Best Practices

✅ **DO**
- Test in dev/staging first
- Review plan output before approval
- Keep terraform code in `terraform/` directory
- Use semantic branch names
- Enable storage versioning
- Test rollback procedures

❌ **DON'T**
- Make manual changes in Azure
- Skip security scanning
- Merge without reviewing plan
- Disable approval gates in production
- Commit secrets to Git

## 🔗 Quick Links

- [Azure OIDC Setup](https://docs.microsoft.com/azure/developer/github/connect-from-azure)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
- [Checkov Policies](https://www.checkov.io/5.Policy%20Index/azure.html)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)

## ⏱️ Setup Time: ~1.5-2 hours

- Azure: 30-45 min
- GitHub: 15-20 min
- Terraform: 20-30 min
- Testing: 15-30 min

---

**Version**: 1.0.0 | **Last Updated**: 2024-02-09
