# Azure Terraform CI/CD Workflows

This directory contains GitHub Actions workflows for automated Azure Terraform deployments using a parent/child reusable workflow pattern.

## 📁 Workflow Files

### Parent Workflow (Reusable Component)

**File**: `azure-terraform-deploy-reusable.yml`

**Purpose**: Reusable workflow that provides standardized Terraform deployment capabilities for Azure.

**⚠️ Important**: This file should be moved to `nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml` once the central workflows repository is created.

**Jobs**:
- ✅ **validate**: Terraform format, validation, and TFLint checks
- 🔒 **security**: Checkov security scanning (fails on violations)
- 📊 **plan**: Generate and save Terraform plan (comments on PRs)
- 🚀 **apply**: Deploy with manual approval gate (main branch only)

**Features**:
- Azure OIDC authentication (no stored credentials)
- Security-first approach (Checkov, TFLint, pinned actions)
- Plan artifact reuse (prevents drift)
- Environment protection with approvals
- Comprehensive PR comments

### Child Workflow (Consumer Example)

**File**: `example-azure-terraform-child.yml`

**Purpose**: Example implementation showing how to use the parent reusable workflow.

**Usage**: Teams should copy and customize this workflow for their repositories.

**Triggers**:
- Push to `main` branch (after PR merge)
- Pull requests to `main` (validation only)
- Manual workflow dispatch (with environment selection)

## 🚀 Quick Start

### For New Repositories

1. **Copy the example workflow**:
   ```bash
   cp .github/workflows/example-azure-terraform-child.yml \
      .github/workflows/terraform-deploy.yml
   ```

2. **Configure Azure OIDC** (see [DEPLOYMENT.md](../docs/DEPLOYMENT.md)):
   - Create Azure AD App Registration
   - Configure federated credentials
   - Create storage account for Terraform state

3. **Add GitHub Secrets**:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

4. **Create Environment Protection**:
   - Settings → Environments → New environment → `production`
   - Add required reviewers

5. **Configure Terraform Backend** in `terraform/terraform.tf`:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "terraform-state-rg"
       storage_account_name = "tfstate12345"
       container_name       = "tfstate"
       key                  = "production.terraform.tfstate"
       use_oidc            = true
     }
   }
   ```

6. **Test the workflow**:
   - Create a PR with Terraform changes
   - Review validation and plan output
   - Merge to trigger deployment

## 🏗️ Architecture

```
┌──────────────────────────────────────┐
│ Team Repository                      │
│ ├── .github/workflows/               │
│ │   └── terraform-deploy.yml         │◄─── Child workflow
│ └── terraform/                       │
│     ├── main.tf                      │
│     └── terraform.tf                 │
└──────┬───────────────────────────────┘
       │
       │ calls (uses:)
       ▼
┌──────────────────────────────────────┐
│ nathlan/.github-workflows            │
│ └── .github/workflows/               │
│     └── azure-terraform-deploy.yml   │◄─── Parent workflow
└──────────────────────────────────────┘
       │
       │ deploys to
       ▼
┌──────────────────────────────────────┐
│ Azure Subscription                   │
│ ├── Resource Groups                  │
│ ├── Virtual Networks                 │
│ └── Other Resources                  │
└──────────────────────────────────────┘
```

## 📋 Workflow Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (production, staging, etc.) |
| `terraform-version` | No | `1.9.0` | Terraform version to use |
| `working-directory` | No | `terraform` | Directory containing Terraform code |
| `azure-region` | No | `uksouth` | Azure region for deployment |

## 🔐 Required Secrets

| Secret | Description | Where to Find |
|--------|-------------|---------------|
| `AZURE_CLIENT_ID` | Azure AD App Client ID | Azure Portal → App Registrations |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | Azure Portal → Azure Active Directory |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | Azure Portal → Subscriptions |

## 🔄 Workflow Behavior

### On Pull Request

1. Runs validation (format, validate, TFLint)
2. Runs security scan (Checkov)
3. Generates Terraform plan
4. Posts plan as PR comment
5. **Does NOT apply changes**

### On Merge to Main

1. Re-runs validation
2. Re-runs security scan
3. Generates fresh plan
4. **Pauses for manual approval**
5. Applies changes (if approved)
6. Saves outputs as artifact

### On Manual Trigger

1. Allows environment selection
2. Follows same flow as merge to main
3. Requires approval before apply

## 🛡️ Security Features

- ✅ **No stored credentials**: OIDC authentication
- ✅ **Pinned action versions**: Supply chain security
- ✅ **Security scanning**: Checkov (fails on violations)
- ✅ **Code quality**: TFLint checks
- ✅ **Manual approval**: Human oversight required
- ✅ **Plan verification**: Saved plan prevents drift
- ✅ **Audit trail**: Environment protection logs

## 📦 Generated Artifacts

All artifacts are retained for 30 days:

1. **checkov-report**: Security scan results (JUnit XML)
2. **terraform-plan-{environment}**: Binary plan file + text output
3. **terraform-outputs-{environment}**: JSON file with Terraform outputs

## 🎯 Best Practices

### DO

- ✅ Test changes in non-production environments first
- ✅ Keep Terraform code in `terraform/` directory at repo root
- ✅ Use semantic branch names (e.g., `feature/add-vnet`)
- ✅ Write descriptive commit messages
- ✅ Review plan output before approving
- ✅ Tag deployments with versions
- ✅ Enable storage account versioning for state files
- ✅ Regularly test rollback procedures

### DON'T

- ❌ Make manual changes in Azure Portal (causes drift)
- ❌ Skip security scanning (use skip-check sparingly)
- ❌ Merge without reviewing plan
- ❌ Disable approval gates in production
- ❌ Commit secrets to version control
- ❌ Use long-lived credentials
- ❌ Deploy large changes without testing

## 🔧 Customization Examples

### Multiple Environments

```yaml
# .github/workflows/terraform-deploy.yml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [production, staging, development]

jobs:
  deploy-staging:
    if: github.event_name == 'pull_request'
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: staging
      working-directory: terraform
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_STAGING }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_STAGING }}

  deploy-production:
    if: github.ref == 'refs/heads/main'
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: production
      working-directory: terraform
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_PROD }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_PROD }}
```

### Different Terraform Version

```yaml
jobs:
  deploy:
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: production
      terraform-version: '1.10.0'  # Use specific version
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Custom Working Directory

```yaml
jobs:
  deploy:
    uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
    with:
      environment: production
      working-directory: infrastructure  # Not 'terraform'
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## 📚 Documentation

- **[DEPLOYMENT.md](../docs/DEPLOYMENT.md)**: Complete setup and deployment guide
- **[TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)**: Common issues and solutions
- **[ROLLBACK.md](../docs/ROLLBACK.md)**: Rollback procedures

## 🔍 Monitoring

### View Workflow Runs

```bash
# List recent runs
gh run list --workflow=terraform-deploy.yml

# Watch current run
gh run watch

# View logs
gh run view --log
```

### Check Terraform State

```bash
# List resources in state
cd terraform/
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.example

# Refresh state from Azure
terraform refresh
```

### Download Artifacts

```bash
# Download plan artifact
gh run download <run-id> --name terraform-plan-production

# View plan
cd terraform-plan-production/
cat plan.txt
```

## 🆘 Troubleshooting

### Common Issues

1. **OIDC Authentication Failed**
   - Verify federated credentials are configured
   - Check GitHub secrets are set correctly
   - Ensure `id-token: write` permission

2. **Backend Initialization Failed**
   - Verify storage account exists
   - Check service principal has Storage Blob Data Contributor role
   - Ensure `use_oidc = true` in backend config

3. **Checkov Failures**
   - Review security violations in artifact
   - Fix misconfigurations in Terraform code
   - Use skip-check only for valid exceptions

4. **Plan Shows Unexpected Changes**
   - Check for manual changes in Azure
   - Review state drift
   - Consider terraform refresh

See [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) for detailed solutions.

## 🤝 Contributing

### Improving the Parent Workflow

To propose changes to the parent reusable workflow:

1. Open an issue in `nathlan/.github-workflows`
2. Describe the improvement or bug fix
3. Submit a PR with changes
4. Tag platform team for review

### Feedback

Found a bug or have a suggestion?

- Open an issue in this repository
- Contact the platform team on Slack
- Submit a PR with improvements

## 📈 Metrics & KPIs

Track these metrics to measure deployment success:

- **Deployment frequency**: How often do you deploy?
- **Lead time**: Time from commit to production
- **Change failure rate**: % of deployments causing incidents
- **Mean time to recovery**: Time to rollback/fix
- **Security scan pass rate**: % of scans without violations
- **Plan accuracy**: How often plans match actual changes

## 🔗 Related Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm)
- [Azure OIDC Setup Guide](https://docs.microsoft.com/azure/developer/github/connect-from-azure)
- [Checkov Azure Policies](https://www.checkov.io/5.Policy%20Index/azure.html)
- [TFLint Rules](https://github.com/terraform-linters/tflint)

## 📞 Support

- **Platform Team**: [Add contact info]
- **Slack Channel**: [Add channel link]
- **Email**: [Add email]
- **Emergency**: [Add on-call info]

---

**Version**: 1.0.0
**Last Updated**: 2024-02-09
**Maintained By**: Platform Engineering Team

🚀 **Ready to automate your deployments?** Follow the [DEPLOYMENT.md](../docs/DEPLOYMENT.md) guide to get started!
