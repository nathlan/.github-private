# Setup Instructions for terraform-azurerm-app-service Module Repository

## Overview
This document provides step-by-step instructions to:
1. Create a new repository for the Azure App Service Terraform module
2. Set up the module in a new branch with a PR
3. Update the .github-private repository to consume the new module

## Prerequisites
- GitHub account with access to create repositories under `nathlan` organization/user
- GitHub CLI (`gh`) installed and authenticated, OR access to GitHub web interface
- Git installed

---

## Part 1: Create and Set Up the New Module Repository

### Step 1: Create the GitHub Repository

#### Option A: Using GitHub CLI (Recommended)
```bash
gh repo create nathlan/terraform-azurerm-app-service \
  --private \
  --description "Terraform module for Azure App Service with App Service Plan, consuming Azure Verified Modules (AVM)" \
  --clone
```

#### Option B: Using GitHub Web Interface
1. Navigate to: https://github.com/new
2. Fill in the details:
   - **Owner**: nathlan
   - **Repository name**: `terraform-azurerm-app-service`
   - **Description**: `Terraform module for Azure App Service with App Service Plan, consuming Azure Verified Modules (AVM)`
   - **Visibility**: Private (recommended)
   - **Initialize**: Do NOT check "Add a README file" (we'll add our own)
3. Click "Create repository"
4. Clone the repository:
   ```bash
   git clone https://github.com/nathlan/terraform-azurerm-app-service.git
   cd terraform-azurerm-app-service
   ```

### Step 2: Run the Automated Setup Script

An automated setup script has been prepared. Run it from the `.github-private` repository:

```bash
# Navigate to the .github-private repository
cd /home/runner/work/.github-private/.github-private

# Run the setup script (assuming the new repo was created)
bash /tmp/setup-module-repo.sh
```

This script will:
- ✅ Clone the new repository
- ✅ Create a `feature/initial-module` branch
- ✅ Copy all module files from .github-private
- ✅ Create necessary files (LICENSE, CHANGELOG.md, .gitignore)
- ✅ Commit the changes
- ✅ Push the branch
- ✅ Create a pull request

### Step 3: Manual Setup (If Script Fails)

If the automated script doesn't work, follow these manual steps:

```bash
# Clone and setup
git clone https://github.com/nathlan/terraform-azurerm-app-service.git
cd terraform-azurerm-app-service
git checkout -b feature/initial-module

# Copy files from .github-private repository
SOURCE="/home/runner/work/.github-private/.github-private"
cp $SOURCE/main.tf .
cp $SOURCE/variables.tf .
cp $SOURCE/outputs.tf .
cp $SOURCE/versions.tf .
cp $SOURCE/README.md .
cp $SOURCE/.tflint.hcl .

# Create .gitignore
cat > .gitignore << 'EOF'
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.tfvars
!examples/**/*.tfvars
*.bak
EOF

# Copy examples
mkdir -p examples/basic
cp $SOURCE/examples/basic/main.tf examples/basic/
cp $SOURCE/examples/basic/README.md examples/basic/

# Create LICENSE
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Commit and push
git add .
git commit -m "feat: initial Azure App Service module with AVM integration"
git push -u origin feature/initial-module

# Create PR
gh pr create \
  --title "feat: initial Azure App Service module with AVM integration" \
  --body "Initial implementation of Azure App Service Terraform module" \
  --base main
```

---

## Part 2: Update .github-private Repository to Consume the Module

After the module repository is created and the PR is merged:

### Step 1: Create a New Branch in .github-private

```bash
cd /home/runner/work/.github-private/.github-private
git checkout -b feature/consume-app-service-module
```

### Step 2: Remove Inline Module Files

```bash
# Remove the inline module files (they're now in the separate repo)
git rm main.tf variables.tf outputs.tf versions.tf
git rm -r examples/basic/
git rm MODULE_CREATION_REPORT.md VALIDATION_RESULTS.md
```

### Step 3: Create Example That Consumes the New Module

Create a new example directory structure:

```bash
mkdir -p examples/app-service-consumption
```

Create `examples/app-service-consumption/main.tf`:

```hcl
# Example: Consuming terraform-azurerm-app-service module

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.19.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-appservice-example"
  location = "East US"
}

# Consume the module from the separate repository
module "app_service" {
  source = "github.com/nathlan/terraform-azurerm-app-service?ref=v1.0.0"

  name                = "mywebapp"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  os_type  = "Linux"
  sku_name = "P1v3"

  application_stack = {
    node_version = "20-lts"
  }

  managed_identities = {
    system_assigned = true
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}

output "app_service_url" {
  value = module.app_service.app_service_default_site_hostname
}
```

Create `examples/app-service-consumption/README.md`:

```markdown
# App Service Module Consumption Example

This example demonstrates how to consume the `terraform-azurerm-app-service` module from the separate repository.

## Module Source

The module is referenced from: `github.com/nathlan/terraform-azurerm-app-service?ref=v1.0.0`

## Usage

1. Initialize Terraform:
   \`\`\`bash
   terraform init
   \`\`\`

2. Plan:
   \`\`\`bash
   terraform plan
   \`\`\`

3. Apply:
   \`\`\`bash
   terraform apply
   \`\`\`

## Notes

- The module is versioned using git tags
- Use `?ref=v1.0.0` to pin to a specific version
- Use `?ref=main` for the latest version (not recommended for production)
```

### Step 4: Update README.md

Update the main README.md to reflect the change:

```markdown
# Custom Agents Template

This template repository makes it easy for enterprise and organization owners to get started with Copilot custom agents by providing:
* The basic file structure necessary for custom agents
* Example agent profiles in the `agents` directory
* Example Terraform module consumption patterns

## Terraform Modules

This repository includes examples of consuming private Terraform modules:

- **terraform-azurerm-app-service**: Azure App Service module - See `examples/app-service-consumption/`

For module development, see the respective module repositories.
```

### Step 5: Commit and Push

```bash
git add .
git commit -m "refactor: move app service module to separate repository

- Remove inline module files (moved to terraform-azurerm-app-service repo)
- Add example showing how to consume the module from separate repo
- Update documentation"

git push -u origin feature/consume-app-service-module
```

### Step 6: Create PR in .github-private

```bash
gh pr create \
  --title "refactor: move app service module to separate repository" \
  --body "Refactors the inline App Service module into a separate repository for better maintainability and versioning.

Changes:
- Removed inline module files (now in terraform-azurerm-app-service repo)
- Added example showing module consumption from separate repo
- Updated documentation

Related Repository: https://github.com/nathlan/terraform-azurerm-app-service" \
  --base main
```

---

## Summary

After completing these steps, you will have:

1. ✅ A new `terraform-azurerm-app-service` repository with:
   - Complete module implementation
   - Documentation
   - Examples
   - A PR for review

2. ✅ Updated `.github-private` repository with:
   - Example of consuming the new module
   - Removed inline module files
   - A PR for review

## Verification

To verify everything works:

1. In the new module repo, check that the PR is created and all files are present
2. In the .github-private repo, verify the consumption example initializes:
   ```bash
   cd examples/app-service-consumption
   terraform init
   terraform validate
   ```

## Next Steps

1. Review and merge the PR in `terraform-azurerm-app-service`
2. Tag the release: `git tag v1.0.0 && git push origin v1.0.0`
3. Review and merge the PR in `.github-private`
4. The module is now ready to use in your infrastructure code!
