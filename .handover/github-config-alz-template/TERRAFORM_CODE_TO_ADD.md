# Terraform Code to Add to github-config Repository

## Instructions for GitHub Config Agent

You will be creating/modifying files DIRECTLY in the `nathlan/github-config` repository, NOT in this .github-private repo.

## File 1: terraform/main.tf

**Action:** ADD the following resource to the EXISTING `main.tf` file (append at the end)

```hcl
# ============================================================================
# ALZ Workload Template Repository Configuration
# ============================================================================
# This section manages the alz-workload-template repository, ensuring it is
# properly configured as a GitHub template repository for creating new
# workload repositories in the ALZ vending system.
#
# CRITICAL: This repository ALREADY EXISTS. It must be imported before apply:
#   terraform import github_repository.alz_workload_template alz-workload-template

resource "github_repository" "alz_workload_template" {
  name        = "alz-workload-template"
  description = "Template repository for ALZ workload repositories with pre-configured Terraform workflows"
  visibility  = "public"

  # CRITICAL: Mark as template repository
  # This enables the "Use this template" button and allows the ALZ vending
  # system to create new repositories from this template via Terraform
  is_template = true

  # Repository features
  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Merge settings - aligned with ALZ standards
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true

  # Security settings
  vulnerability_alerts = true

  # Topics for discoverability
  topics = [
    "azure",
    "terraform",
    "template",
    "landing-zone",
    "alz"
  ]

  lifecycle {
    # Prevent accidental deletion of the template repository
    prevent_destroy = true
  }
}
```

## File 2: terraform/outputs.tf

**Action:** ADD the following outputs to the EXISTING `outputs.tf` file (append at the end)

```hcl
# ALZ Workload Template Repository Outputs
output "alz_workload_template_name" {
  description = "Name of the ALZ workload template repository"
  value       = github_repository.alz_workload_template.name
}

output "alz_workload_template_url" {
  description = "URL of the ALZ workload template repository"
  value       = github_repository.alz_workload_template.html_url
}

output "alz_workload_template_is_template" {
  description = "Whether the repository is marked as a template"
  value       = github_repository.alz_workload_template.is_template
}
```

## File 3: terraform/IMPORT_INSTRUCTIONS.md

**Action:** CREATE this new file

```markdown
# Import Instructions for alz-workload-template

## Overview

The `alz-workload-template` repository **ALREADY EXISTS** in GitHub. This Terraform configuration will import and manage the existing repository, specifically to set `is_template = true`.

## Critical: Import Before Apply

⚠️ **You MUST import the existing repository into Terraform state before running `terraform apply`.**

If you skip the import step, Terraform will try to create a new repository, which will fail because the repository already exists.

## Import Workflow

```bash
cd terraform/

# 1. IMPORT existing repository first
terraform import github_repository.alz_workload_template alz-workload-template

# 2. Review what will change
terraform plan -var="github_organization=nathlan"
# Expected: is_template: false → true

# 3. Apply configuration
terraform apply -var="github_organization=nathlan"

# 4. Verify in GitHub UI
open https://github.com/nathlan/alz-workload-template
# Check for "Use this template" button
```

## What Changes

- ✅ Repository imported into Terraform state
- ✅ `is_template = true` set on existing repository  
- ✅ Repository settings aligned with config
- ❌ NO changes to repository content, files, or history
- ❌ NO new repository created

This is an **import and configure** operation, not a create operation.
```

## Important Notes

1. **APPEND, don't replace:** For main.tf and outputs.tf, ADD the new code at the end of the existing file
2. **IMPORT required:** The repository exists, so import must be run before apply
3. **is_template attribute:** The GitHub provider v6.0+ supports this attribute
