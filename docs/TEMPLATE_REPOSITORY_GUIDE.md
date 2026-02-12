# Template Repository Guide

This guide explains how template repositories are used in the ALZ vending system and how to manage them.

## Overview

Template repositories provide a standardized starting point for new repositories, ensuring consistency across the organization. When creating a new repository from a template, GitHub copies all files and directory structure to the new repository.

## Current Template Repositories

### alz-workload-template

**Repository:** `nathlan/alz-workload-template`  
**Purpose:** Standard base for all Azure Landing Zone workload repositories  
**Status:** Template repository (requires `is_template: true` flag)

**Includes:**
- Pre-configured GitHub Actions workflows (child workflow pattern)
- Terraform directory structure with starter files
- Azure OIDC authentication setup with dual-identity model (plan/apply)
- Standard `.gitignore` for Terraform
- Comprehensive README with setup instructions
- Security scanning and validation workflows

## Why Use Template Repositories?

### Benefits

1. **Consistency:** All new repositories start with the same structure and standards
2. **Speed:** Developers don't need to manually set up workflows and configuration
3. **Best Practices:** Templates encode organizational standards and security requirements
4. **Maintainability:** Updates to the template apply to future repositories
5. **Compliance:** Ensures security scanning and validation are included from day one

### When to Use Templates

✅ **Use Template Repository When:**
- Creating Azure workload repositories
- Need pre-configured CI/CD workflows
- Want to enforce organizational standards
- Starting a new project that fits an existing pattern

❌ **Don't Use Template When:**
- Creating infrastructure repositories (e.g., `alz-subscriptions`, `.github-workflows`)
- Building special-purpose repositories with unique requirements
- Creating the template repository itself

## Template Repository Structure

### alz-workload-template Structure

```
alz-workload-template/
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # Child workflow that calls parent
├── terraform/
│   ├── main.tf                     # Starter Terraform configuration
│   ├── variables.tf                # Common input variables
│   ├── outputs.tf                  # Standard outputs
│   ├── terraform.tf                # Backend and provider configuration
│   └── .gitignore                  # Terraform-specific ignore patterns
├── .gitignore                      # Repository ignore patterns
└── README.md                       # Template documentation with setup guide
```

### Key Files Explained

#### `.github/workflows/terraform-deploy.yml`

Child workflow that implements the parent/child pattern:
- Calls the reusable parent workflow in `.github-workflows` repository
- Provides environment-specific configuration
- Inherits validation, security scanning, and deployment logic

**Benefits:**
- Central workflow updates automatically benefit all workload repos
- No need to duplicate workflow logic across repositories
- Easier to maintain and update deployment processes

#### `terraform/terraform.tf`

Backend and provider configuration:
```hcl
terraform {
  required_version = ">= 1.9.0"
  
  backend "azurerm" {
    # Values provided via backend config or environment variables
    use_oidc = true
  }
  
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
```

#### README.md

Comprehensive setup guide including:
- Repository structure overview
- Workflow deployment process
- Azure OIDC setup with dual-identity model
- Secret configuration instructions
- Environment setup guide

## Setting Up a Repository as a Template

### Prerequisites

- Admin access to the repository
- Repository contains standard files and workflows
- Repository structure is tested and validated
- Documentation is complete and accurate

### Step-by-Step Setup

#### 1. Prepare the Repository

Ensure the repository contains:
- [ ] All necessary files and directory structure
- [ ] Pre-configured workflows that work with the parent/child pattern
- [ ] Comprehensive README with setup instructions
- [ ] Appropriate `.gitignore` files
- [ ] Example or starter code where applicable

#### 2. Enable Template Flag

**Manual Process (Required):**

1. Navigate to repository settings:
   ```
   https://github.com/nathlan/alz-workload-template/settings
   ```

2. Scroll to "Template repository" section

3. Check the "Template repository" checkbox

4. Read the information about template repositories

5. Save changes

**Verification:**
- Visit the repository homepage
- Confirm "Use this template" button appears (green button, top-right)

**Note:** The template flag (`is_template: true`) cannot be set via GitHub MCP tools or the GitHub API. This is a GitHub UI-only operation that requires manual configuration.

#### 3. Test the Template

Create a test repository from the template:

1. Click "Use this template" → "Create a new repository"
2. Name: `test-template-{timestamp}`
3. Verify all files are copied correctly
4. Test workflows execute successfully
5. Delete the test repository after validation

#### 4. Document Template Usage

Update documentation to reference the template:
- Add template to this guide
- Update relevant agent instructions
- Create examples showing template usage
- Document any customization steps required after template use

## Using Templates in Terraform

### GitHub Provider Configuration

When creating repositories from templates using the `github-config` agent, use the `template` block:

```hcl
resource "github_repository" "new_workload" {
  name        = "my-workload"
  description = "My Azure workload repository"
  visibility  = "internal"

  # CRITICAL: Specify template for new repos
  template {
    owner      = "nathlan"
    repository = "alz-workload-template"
  }

  # Standard settings
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  delete_branch_on_merge = true
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false

  topics = ["azure", "terraform", "my-workload"]
}
```

### Complete Example

See the "Repository Creation from Templates" section in `agents/github-config.agent.md` for a complete example including:
- Variable definitions with validation
- Data sources for teams
- Repository creation from template
- Team access configuration
- Branch protection rules
- Output definitions

## Template Maintenance

### Updating Template Content

**When to Update:**
- Security improvements needed
- New organizational standards
- Workflow enhancements
- Bug fixes in starter code

**Update Process:**

1. **Create a Branch:**
   ```bash
   git checkout -b update/template-improvement
   ```

2. **Make Changes:**
   - Update workflows, documentation, or configuration
   - Test changes thoroughly
   - Ensure backward compatibility where possible

3. **Test in Isolation:**
   - Create a test repository from the updated template
   - Verify all functionality works
   - Test workflow execution

4. **Document Changes:**
   - Update README if necessary
   - Add release notes or changelog
   - Note any breaking changes

5. **Merge via PR:**
   - Create pull request
   - Get review from platform team
   - Merge to main branch

### Impact of Template Updates

**Important:** Template updates only affect **new** repositories created after the update.

**Existing repositories are NOT automatically updated when the template changes.**

**To Update Existing Repositories:**

1. **Manual Replication:**
   - Identify affected repositories
   - Manually apply changes via PRs
   - Document changes in PR description

2. **Automated Updates (via GitHub MCP):**
   - Use `github-config` agent to update specific files
   - Create Terraform code to push file updates
   - Apply to multiple repositories using `for_each`

3. **Migration Terraform Code:**
   - Write Terraform to update common files
   - Use `github_repository_file` resource
   - Target specific repositories needing updates

### Versioning Templates

**Approach 1: Branches**
- Maintain version branches (e.g., `v1`, `v2`)
- Create repositories from specific branches
- Document which version is current

**Approach 2: Tags**
- Tag template versions (e.g., `v1.0.0`, `v1.1.0`)
- Reference tags in documentation
- Track which version is recommended

**Approach 3: Single Main Branch (Current)**
- Keep template on `main` branch
- Document breaking changes in commits
- Update existing repos manually when needed

## GitHub Config Agent Integration

### Agent Behavior

The `github-config` agent is configured to:

1. **Always Use Templates for Workload Repos:**
   - Check if repository request is for Azure workload
   - Automatically include template block in Terraform
   - Use `alz-workload-template` as the default template

2. **Validate Template Exists:**
   - Verify template repository exists before generation
   - Check template flag is enabled
   - Warn if template is not accessible

3. **Document Template Usage:**
   - Include template information in PR description
   - Explain what the template provides
   - Document post-creation steps if needed

### Handoff from ALZ Vending Agent

When the `alz-vending` agent hands off to `github-config`, it now includes:

```
**CRITICAL: Use Template Repository**
- Template: nathlan/alz-workload-template (REQUIRED for all workload repos)
- This ensures pre-configured workflows, Terraform structure, and standards
```

This ensures the github-config agent knows to use the template.

## Troubleshooting

### Template Button Not Visible

**Problem:** "Use this template" button doesn't appear on repository

**Solution:**
1. Verify you have admin access to the repository
2. Check Settings → Template repository is enabled
3. Ensure repository is not empty
4. Try refreshing the page or logging out/in

### Template Creation Fails in Terraform

**Problem:** `terraform apply` fails when creating repository from template

**Error Example:**
```
Error: template repository is not a template
```

**Solutions:**
1. Verify `is_template: true` is set in GitHub UI (cannot be set via API)
2. Check template repository exists and is accessible
3. Ensure organization has access to the template repository
4. Verify GitHub token has appropriate permissions

### Files Not Copied from Template

**Problem:** New repository created but files are missing

**Possible Causes:**
1. Template repository was empty when template flag was enabled
2. Files were added to template after repository creation
3. GitHub API delay in syncing template content

**Solutions:**
1. Manually push missing files to the new repository
2. Use `github_repository_file` resource in Terraform
3. Re-create repository if just created

### Template Updates Not Reflected

**Problem:** Template was updated but new repositories still use old version

**Explanation:** This is expected behavior. GitHub templates copy files at repository creation time. Updates to the template only apply to repositories created after the update.

**Solutions:**
- For new repos: No action needed, they will use the latest template
- For existing repos: Apply updates manually or via automation

## Best Practices

### Template Design

1. **Keep It Simple:**
   - Include only essential files
   - Avoid organization-specific hardcoded values
   - Use placeholder values that users must update

2. **Document Everything:**
   - Comprehensive README with step-by-step setup
   - Inline comments in configuration files
   - Link to additional resources

3. **Use Placeholders:**
   ```hcl
   # terraform/variables.tf
   variable "workload_name" {
     description = "Name of the workload - UPDATE THIS"
     type        = string
     default     = "CHANGEME"
   }
   ```

4. **Test Regularly:**
   - Create test repositories monthly
   - Verify all workflows execute
   - Update documentation as needed

### Using Templates

1. **Always Customize:**
   - Update placeholder values immediately
   - Customize README for specific workload
   - Remove unnecessary files or sections

2. **Test Before Production:**
   - Run workflows in PR before merging
   - Validate Terraform plan output
   - Test Azure authentication

3. **Follow Up:**
   - Complete all setup steps in template README
   - Configure required secrets and variables
   - Set up environment protection rules

## Related Documentation

- **GitHub Config Agent:** `agents/github-config.agent.md`
- **ALZ Vending Agent:** `agents/alz-vending.agent.md`
- **ALZ Manual Configuration:** `ALZ_MANUAL_CONFIGURATION_GUIDE.md`
- **CI/CD Workflow Agent:** `agents/cicd-workflow.agent.md`

## Support

For questions or issues with template repositories:

1. Check this guide first
2. Review the template repository README
3. Contact platform engineering team
4. Create an issue in `.github-private` repository

## Changelog

### 2026-02-11
- Initial documentation created
- Documented `alz-workload-template` as standard template
- Added integration with `github-config` and `alz-vending` agents
- Included troubleshooting guide and best practices
