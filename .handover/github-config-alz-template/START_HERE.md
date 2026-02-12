# START HERE: GitHub Config Agent Instructions

## For GitHub Config Agent (with write permissions via GitHub MCP)

You have complete instructions to import and configure the existing `alz-workload-template` repository.

### 📖 Read These Files in Order:

1. **README.md** - Overview of what you're doing
2. **IMPLEMENTATION_STEPS.md** - Step-by-step instructions to follow
3. **TERRAFORM_CODE_TO_ADD.md** - Exact Terraform code to add
4. **PR_DESCRIPTION.md** - Template for the PR you'll create

### 🎯 Your Task

Modify the `nathlan/github-config` repository to:
- Add Terraform configuration for the **EXISTING** alz-workload-template repository
- Set `is_template = true` to enable template functionality
- Create PR for user review

### ⚠️ CRITICAL POINTS

1. **Repository EXISTS:** The alz-workload-template repository already exists in GitHub
2. **This is IMPORT:** Terraform will import the existing repo, not create a new one
3. **No files here:** You create Terraform files in the github-config repo, not this repo
4. **APPEND, don't replace:** Add code to existing main.tf and outputs.tf files
5. **Write permissions required:** GitHub MCP server must be restarted with your credentials

### 🚀 Quick Start

```bash
# 1. Verify you have the instructions
ls -la /home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/

# 2. Read the implementation steps
cat IMPLEMENTATION_STEPS.md

# 3. Follow the steps exactly
```

### ✅ Success Criteria

- [ ] Branch created in nathlan/github-config
- [ ] terraform/main.tf updated (appended resource)
- [ ] terraform/outputs.tf updated (appended outputs)
- [ ] terraform/IMPORT_INSTRUCTIONS.md created
- [ ] PR created
- [ ] PR URL reported to user

### 📝 After You Complete

The user will:
1. Review and merge your PR
2. Run: `terraform import github_repository.alz_workload_template alz-workload-template`
3. Run: `terraform apply`
4. Verify "Use this template" button appears

---

**Location:** `.handover/github-config-alz-template/`  
**Target Repo:** `nathlan/github-config`  
**Operation:** IMPORT existing repository + configure  
**Status:** Ready for execution
