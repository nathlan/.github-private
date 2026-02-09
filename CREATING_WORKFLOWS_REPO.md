# Creating the .github-workflows Repository

This document explains how to create the `nathlan/.github-workflows` repository and deploy the parent reusable workflow.

## Automated Deployment (Recommended)

### Option 1: Via GitHub UI

1. Go to the **Actions** tab in this repository
2. Select the workflow: **Create .github-workflows Repository**
3. Click **Run workflow**
4. Wait for completion (~30 seconds)

The workflow will automatically:
- ✅ Create the `nathlan/.github-workflows` repository
- ✅ Deploy the reusable workflow to `.github/workflows/azure-terraform-deploy.yml`
- ✅ Add a README with usage instructions

### Option 2: Via GitHub CLI

```bash
gh workflow run create-workflows-repo.yml --repo nathlan/.github-private
```

### Option 3: Via API

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.github.com/repos/nathlan/.github-private/actions/workflows/create-workflows-repo.yml/dispatches \
  -d '{"ref":"main"}'
```

## Manual Deployment (Alternative)

If you prefer manual deployment:

1. **Create the repository**:
   ```bash
   gh repo create nathlan/.github-workflows --public \
     --description "Centralized reusable GitHub Actions workflows for Azure Landing Zone deployments"
   ```

2. **Clone and prepare**:
   ```bash
   git clone https://github.com/nathlan/.github-workflows.git
   cd .github-workflows
   mkdir -p .github/workflows
   ```

3. **Copy the workflow**:
   ```bash
   # From the .github-private repo
   cp /path/to/.github-private/.github/workflows/azure-terraform-deploy-reusable.yml \
      .github/workflows/azure-terraform-deploy.yml
   ```

4. **Create README**:
   ```bash
   cat > README.md << 'EOF'
# Reusable GitHub Actions Workflows

Centralized repository for reusable GitHub Actions workflows for Azure Landing Zone deployments.

## Azure Terraform Deploy Workflow

Path: `.github/workflows/azure-terraform-deploy.yml`

### Usage

See the workflow file for complete documentation and usage instructions.
EOF
   ```

5. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add Azure Terraform reusable workflow"
   git push origin main
   ```

## Verification

After deployment, verify the repository:

1. Visit: https://github.com/nathlan/.github-workflows
2. Check that `.github/workflows/azure-terraform-deploy.yml` exists
3. Review the README

## Next Steps

Once the repository is created:

1. **Update child workflows** to reference the correct location:
   ```yaml
   uses: nathlan/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
   ```

2. **Configure Azure OIDC** in repositories that will use this workflow:
   - See `docs/DEPLOYMENT.md` for instructions

3. **Add required secrets** to consuming repositories:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

4. **Create environment protection** rules:
   - Settings → Environments → `production`
   - Add required reviewers

## Troubleshooting

**Repository already exists**:
- The workflow will fail if the repository already exists
- Delete the existing repository or use a different name

**Permission denied**:
- Ensure you have admin access to the `nathlan` organization
- The `GITHUB_TOKEN` must have `contents: write` permission

**Workflow not visible**:
- Make sure you're on the correct branch (`main` or `copilot/create-parent-child-workflows`)
- Check the `.github/workflows/` directory for `create-workflows-repo.yml`
