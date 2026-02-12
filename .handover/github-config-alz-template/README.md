# GitHub Config Agent Handoff: Configure alz-workload-template

## Overview

This directory contains everything needed for the GitHub Config agent to push Terraform configuration to the `nathlan/github-config` repository to enable `is_template = true` on the `alz-workload-template` repository.

## 🎯 Quick Start for GitHub Config Agent

**Read this file:** `IMPLEMENTATION_STEPS.md`

It contains step-by-step instructions for:
1. Creating a branch in the github-config repository
2. Pushing 3 files to the terraform/ directory
3. Creating a pull request with the provided description
4. Reporting success

## 📁 Files in This Directory

| File | Purpose | Lines |
|------|---------|-------|
| **IMPLEMENTATION_STEPS.md** | Detailed step-by-step instructions for GitHub Config agent | 131 |
| **main.tf** | Complete main.tf with alz-workload-template resource added | 172 |
| **outputs.tf** | Updated outputs including template repository outputs | 24 |
| **IMPORT_INSTRUCTIONS.md** | Instructions for importing and verifying after PR merge | 49 |
| **PR_DESCRIPTION.md** | Complete PR description for the pull request | 170 |
| **README.md** | This file | - |

## 🔑 Key Points

1. **Persistent Storage:** All files are in the .github-private repository, NOT in /tmp/
2. **GitHub Config Agent:** Must be run with GitHub Config agent identity with write permissions
3. **MCP Server:** GitHub MCP server must be restarted with proper authentication
4. **Target Repository:** `nathlan/github-config`
5. **Target Branch:** `terraform/configure-alz-workload-template` (new)
6. **Files to Push:** 3 files to `terraform/` directory

## ✅ Prerequisites

Before the GitHub Config agent can execute:

- [ ] GitHub Config agent identity active
- [ ] GitHub MCP server restarted with write permissions
- [ ] Access to this directory: `/home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/`
- [ ] Write access to `nathlan/github-config` repository verified

## 🚀 Execution

As the GitHub Config agent, run:

```bash
# 1. Verify files exist
ls -la /home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/

# 2. Read implementation steps
cat /home/runner/work/.github-private/.github-private/.handover/github-config-alz-template/IMPLEMENTATION_STEPS.md

# 3. Follow the steps exactly as written
```

## 📊 What This Accomplishes

After the GitHub Config agent completes the task:

1. ✅ Terraform configuration pushed to github-config repository
2. ✅ Pull request created for review
3. ✅ User can merge PR
4. ✅ User can import and apply Terraform
5. ✅ alz-workload-template will have `is_template = true` set
6. ✅ "Use this template" button will appear on the repository

## 🔍 Key Discovery

**Previous documentation was INCORRECT.**

The GitHub Terraform provider (v6.0+) DOES support the `is_template` attribute. It can be set programmatically via Terraform, eliminating the need for manual UI configuration.

## 📝 After Completion

Once the PR is merged and Terraform is applied, update these files in `.github-private`:

1. `docs/TEMPLATE_REPOSITORY_GUIDE.md` - Correct the statement about is_template
2. Confirm agent instructions reference Terraform management

## 🆘 Support

If issues arise:
- Review `IMPLEMENTATION_STEPS.md` troubleshooting section
- Verify GitHub MCP server authentication
- Check write permissions to github-config repository
- Ensure all files are readable in this directory

---

**Directory:** `.handover/github-config-alz-template/`  
**Created:** 2026-02-11  
**For:** GitHub Config Agent with write permissions  
**Status:** Ready for execution
