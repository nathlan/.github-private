# ALZ Infrastructure Deployment - Quick Start

**Created:** 2026-02-09
**Updated:** 2026-02-09
**Status:** ✅ Ready for Implementation

## Overview

The ALZ infrastructure repositories need to be created and populated by an AI agent with GitHub MCP server write access. Complete implementation instructions are provided in `ALZ_IMPLEMENTATION_INSTRUCTIONS.md`.

## Implementation Method

This deployment will be performed by an AI agent with GitHub MCP write capabilities, **NOT** via GitHub Actions workflows.

## For the Implementation Agent

If you are an agent with GitHub MCP server write access, proceed to:

**👉 `ALZ_IMPLEMENTATION_INSTRUCTIONS.md`**

This file contains:
- Complete step-by-step instructions
- All file contents inline (ready to create)
- Repository configuration parameters
- Verification steps

## What Gets Deployed

The agent will create two repositories:

### Repository 1: `nathlan/alz-subscriptions`

Core subscription vending infrastructure with Terraform configuration

### Repository 2: `nathlan/.github-workflows`

Reusable GitHub Actions workflows for Terraform deployments

## Quick Reference

For the implementation agent:
1. Read `ALZ_IMPLEMENTATION_INSTRUCTIONS.md`
2. Create repositories using GitHub MCP
3. Create and commit all specified files
4. Verify repositories are accessible

For humans needing manual deployment:
- See `ALZ_REPO_SETUP_GUIDE.md` for manual methods
- Alternative workflow exists at `.github/workflows/create-alz-infrastructure-repos.yml` (if needed)

## Post-Deployment Configuration

After the agent creates the repositories, the following manual configuration is required:

### 1. Configure Secrets in alz-subscriptions

Add these secrets in Settings → Secrets and variables → Actions:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

### 2. Create Environment in alz-subscriptions

Settings → Environments → New environment:
- Name: `azure-landing-zones`
- Add required reviewers (platform team)
- Add environment secrets (same as above)

### 3. Update Azure Configuration

Edit `agents/alz-vending.agent.md` lines 433-437 with real values:

```bash
# Get values
az account show --query tenantId -o tsv
az billing enrollment-account list --query "[0].id" -o tsv
az network vnet show --resource-group rg-hub-network --name vnet-hub-uksouth --query id -o tsv
```

### 4. Test the ALZ Orchestrator

Once repositories and configuration are complete, test with:

```
@alz-vending

workload_name: test-workload
environment: DevTest
location: uksouth
team_name: platform-engineering
address_space: 10.200.0.0/24
cost_center: TEST-001
```

---

## Files Deployed by Agent

### In `nathlan/alz-subscriptions`:
- Terraform configuration (main.tf, variables.tf, outputs.tf, backend.tf)
- Documentation (README.md, terraform.tfvars.example)
- Configuration (.gitignore, .terraform-version)
- Directory structure (landing-zones/)

### In `nathlan/.github-workflows`:
- Reusable Azure Terraform workflow
- Usage documentation

---

**For detailed implementation instructions:** See `ALZ_IMPLEMENTATION_INSTRUCTIONS.md`

**For manual deployment:** See `ALZ_REPO_SETUP_GUIDE.md`
