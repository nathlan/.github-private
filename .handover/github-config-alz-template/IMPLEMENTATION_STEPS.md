# GitHub Config Agent: Implementation Steps

**CRITICAL:** You are the GitHub Config agent with write permissions via GitHub MCP. Follow these steps EXACTLY.

## Prerequisites Verification

Before starting, verify:
- [ ] You are running as the GitHub Config agent identity
- [ ] GitHub MCP server has been restarted with your credentials
- [ ] You have write access to `nathlan/github-config` repository
- [ ] You can see all files in this directory: `.handover/github-config-alz-template/`

## Step 1: Verify File Availability

All required files are in this directory:

```bash
ls -la /home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/
```

Should show:
- main.tf (5212 bytes)
- outputs.tf (729 bytes)  
- IMPORT_INSTRUCTIONS.md (1435 bytes)
- IMPLEMENTATION_STEPS.md (this file)
- PR_DESCRIPTION.md (PR description template)

## Step 2: Create Branch in github-config Repository

Using GitHub MCP write tools, create a new branch:

**Repository:** `nathlan/github-config`
**Base Branch:** `main`
**New Branch:** `terraform/configure-alz-workload-template`

## Step 3: Push Files to terraform/ Directory

Push these 3 files to the `terraform/` directory (at repository root) in the new branch:

### File 1: terraform/main.tf
**Action:** REPLACE existing file
**Source:** `/home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/main.tf`
**Target:** `terraform/main.tf` in github-config repo

**CRITICAL:** This file includes BOTH the existing configuration AND the new alz-workload-template resource. You MUST replace the entire file, not append.

### File 2: terraform/outputs.tf
**Action:** REPLACE existing file
**Source:** `/home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/outputs.tf`
**Target:** `terraform/outputs.tf` in github-config repo

### File 3: terraform/IMPORT_INSTRUCTIONS.md
**Action:** CREATE new file
**Source:** `/home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/IMPORT_INSTRUCTIONS.md`
**Target:** `terraform/IMPORT_INSTRUCTIONS.md` in github-config repo

## Step 4: Commit Changes

**Commit Message:**
```
feat(github): Configure alz-workload-template as template repository

Add Terraform configuration to manage the alz-workload-template repository
with is_template = true to enable GitHub template functionality.

Changes:
- Add github_repository.alz_workload_template resource with is_template = true
- Configure repository settings aligned with ALZ standards
- Add lifecycle protection to prevent accidental deletion
- Update outputs.tf to export template repository details
- Add IMPORT_INSTRUCTIONS.md with detailed import and verification steps

This eliminates the need for manual UI configuration of the template flag.
```

## Step 5: Create Pull Request

**Title:** `feat: Configure alz-workload-template as GitHub template repository`

**Body:** Use the content from `PR_DESCRIPTION.md` in this directory

**Settings:**
- Base: `main`
- Head: `terraform/configure-alz-workload-template`
- Draft: `false` (ready for review)

## Step 6: Verify PR Created

Confirm:
- [ ] PR is created in `nathlan/github-config` repository
- [ ] PR shows 3 files changed
- [ ] PR description is complete
- [ ] PR is not in draft mode

## Step 7: Report Back

Report the PR URL to the user so they can:
1. Review the changes
2. Merge the PR
3. Run terraform import
4. Apply the configuration

## Troubleshooting

### "Permission Denied" or "403 Forbidden"
- GitHub MCP server not restarted with your credentials
- Restart MCP server as GitHub Config agent identity

### "Files not found"
- Files are in `.handover/github-config-alz-template/` directory
- This directory is in the `.github-private` repository
- Use absolute path: `/home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/`

### "Branch already exists"
- Delete the branch first or use a different branch name with timestamp

## Success Criteria

✅ Branch created in github-config repository
✅ 3 files pushed to terraform/ directory  
✅ Commit message follows conventional commits
✅ PR created and ready for review
✅ PR URL reported to user

## What Happens Next (After PR Merge)

User will:
1. Review and merge PR
2. Import existing repository: `terraform import github_repository.alz_workload_template alz-workload-template`
3. Apply configuration: `terraform apply`
4. Verify template button appears on alz-workload-template repository
