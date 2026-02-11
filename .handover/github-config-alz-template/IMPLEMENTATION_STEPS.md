# GitHub Config Agent: Implementation Steps

**CRITICAL:** You are the GitHub Config agent with write permissions via GitHub MCP. Follow these steps EXACTLY to modify the github-config repository.

## Prerequisites Verification

Before starting, verify:
- [ ] You are running as the GitHub Config agent identity
- [ ] GitHub MCP server has been restarted with your credentials
- [ ] You have write access to `nathlan/github-config` repository

## Overview

You will IMPORT the EXISTING `alz-workload-template` repository into Terraform management and configure `is_template = true`. The repository already exists - this is NOT a create operation.

## Step 1: Read Terraform Code

Read the file: `TERRAFORM_CODE_TO_ADD.md` in this directory

It contains the exact Terraform code to add to the github-config repository.

## Step 2: Create Branch in github-config Repository

Using GitHub MCP write tools:

**Repository:** `nathlan/github-config`
**Base Branch:** `main`
**New Branch:** `terraform/configure-alz-workload-template`

## Step 3: Modify terraform/main.tf

**Action:** APPEND (add to the end of the existing file)

Get current content of `terraform/main.tf` from github-config repo, then ADD this resource at the end:

```hcl
# ============================================================================
# ALZ Workload Template Repository Configuration
# ============================================================================
# CRITICAL: This repository ALREADY EXISTS. Import required:
#   terraform import github_repository.alz_workload_template alz-workload-template

resource "github_repository" "alz_workload_template" {
  name        = "alz-workload-template"
  description = "Template repository for ALZ workload repositories with pre-configured Terraform workflows"
  visibility  = "public"
  is_template = true

  has_issues   = true
  has_projects = false
  has_wiki     = false

  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true

  vulnerability_alerts = true

  topics = ["azure", "terraform", "template", "landing-zone", "alz"]

  lifecycle {
    prevent_destroy = true
  }
}
```

## Step 4: Modify terraform/outputs.tf

**Action:** APPEND (add to the end of the existing file)

Get current content of `terraform/outputs.tf` from github-config repo, then ADD these outputs at the end:

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

## Step 5: Create terraform/IMPORT_INSTRUCTIONS.md

**Action:** CREATE new file

See `TERRAFORM_CODE_TO_ADD.md` for the complete content.

## Step 6: Commit Changes

**Commit Message:**
```
feat(github): Import and configure alz-workload-template as template repository

Add Terraform configuration to import existing alz-workload-template repository
and set is_template = true to enable GitHub template functionality.

CRITICAL: This imports an EXISTING repository, not creating a new one.

Changes:
- Add github_repository.alz_workload_template resource (import required)
- Configure is_template = true to enable template functionality
- Add lifecycle protection to prevent accidental deletion
- Add outputs for template repository details
- Add IMPORT_INSTRUCTIONS.md with import workflow

Before applying:
  terraform import github_repository.alz_workload_template alz-workload-template
```

## Step 7: Create Pull Request

**Title:** `feat: Import and configure alz-workload-template as template repository`

**Body:** Use content from `PR_DESCRIPTION.md` in this directory

**Settings:**
- Base: `main`
- Head: `terraform/configure-alz-workload-template`
- Draft: `false` (ready for review)

## Step 8: Report Back

Report the PR URL to the user.

## Success Criteria

✅ Branch created in github-config repository
✅ terraform/main.tf updated (appended resource)
✅ terraform/outputs.tf updated (appended outputs)
✅ terraform/IMPORT_INSTRUCTIONS.md created
✅ Commit message emphasizes IMPORT of existing resource
✅ PR created and ready for review
✅ PR URL reported to user

## After PR Merge (User Actions)

The user will:

1. **Import existing repository:**
   ```bash
   terraform import github_repository.alz_workload_template alz-workload-template
   ```

2. **Review changes:**
   ```bash
   terraform plan
   # Expected: is_template: false → true
   ```

3. **Apply configuration:**
   ```bash
   terraform apply
   ```

4. **Verify:** Check that "Use this template" button appears on alz-workload-template

## Troubleshooting

### "Permission Denied" or "403 Forbidden"
- GitHub MCP server not restarted with your credentials
- Restart MCP server as GitHub Config agent identity

### "Branch already exists"
- Use a different branch name with timestamp or delete existing branch first

---

**Key Point:** This is an **IMPORT and CONFIGURE** operation. The alz-workload-template repository ALREADY EXISTS. Terraform will import it into state, then configure `is_template = true`.
