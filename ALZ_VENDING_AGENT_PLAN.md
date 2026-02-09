# ALZ Subscription Vending Orchestrator — Implementation Plan

> **Status:** Draft v2  
> **Created:** 2026-02-09  
> **Author:** Custom Agent Foundry  
> **Sources:** Azure CAF docs, `Azure/lz-vending/azurerm` v7.0.3, `nathlan/terraform-azurerm-landing-zone-vending` (private wrapper), existing agents (github-config, cicd-workflow, terraform-module-creator)

---

## 1. Executive Summary

Build an **ALZ Vending Orchestrator Agent** — a pure orchestrator that enables developers to self-service request a new Corp Azure Landing Zone. It gathers requirements, creates a `.tfvars` file PR in the ALZ infra repo, hands off to specialist agents for GitHub repo config and CI/CD workflows, and tracks the entire lifecycle via a GitHub Issue.

**This agent does NOT generate Terraform code or CI/CD workflows.** It delegates those responsibilities to existing specialist agents and focuses exclusively on:
- Requirements gathering (intake form)
- Generating a `.tfvars` parameter file (data, not code)
- Orchestrating handoffs to specialist agents with structured prompts
- Tracking PR lifecycle across repos
- Reporting status and completion to the user

### Architecture Principle: Orchestrate, Don't Implement

| Concern | Owner | This Agent's Role |
|---|---|---|
| Terraform module for LZ vending | `terraform-module-creator` agent + `nathlan/terraform-azurerm-landing-zone-vending` | Assumes module exists; generates `.tfvars` input data |
| GitHub repo/team/branch protection config | `github-config` agent | Provides structured requirements via handoff prompt |
| CI/CD workflows (plan/apply) | `cicd-workflow` agent | Provides structured requirements via handoff prompt |
| LZ infra repo CI/CD pipeline | Exists (managed by platform team) | Assumes pipeline exists; monitors PR status |
| Requirements gathering | **This agent** | Primary responsibility |
| PR lifecycle tracking | **This agent** | Primary responsibility |
| User communication | **This agent** | Primary responsibility |

---

## 2. Existing Infrastructure (Assumed In-Place)

### 2.1 Private LZ Vending Module

**Repo:** `nathlan/terraform-azurerm-landing-zone-vending`  
**Wraps:** `Azure/avm-ptn-alz-sub-vending/azure` v0.1.0  
**Current state:** v1.0.2 (PR open for terraform version constraint)

**Current variables exposed:**
- `location`, `subscription_alias_enabled`, `subscription_billing_scope`, `subscription_display_name`
- `subscription_alias_name`, `subscription_workload`, `subscription_management_group_id`
- `subscription_tags`, `subscription_management_group_association_enabled`
- `resource_group_creation_enabled`, `resource_groups`
- `role_assignment_enabled`, `role_assignments`
- `virtual_network_enabled`, `virtual_networks`

**Not yet exposed (prerequisite enhancement needed):**
- `umi_enabled`, `user_managed_identities` (for UMI + federated credentials)
- `budget_enabled`, `budgets`

> **Prerequisite:** The `terraform-module-creator` agent should be tasked with adding UMI + budget pass-through variables to the private wrapper module before this orchestrator can fully automate workload identity federation. Until then, the orchestrator's `.tfvars` output will include the UMI/budget section commented out with a note, or the wrapper module will need to be extended first.

### 2.2 ALZ Infra Repo

**Repo:** `{org}/alz-subscriptions` (placeholder — to be confirmed)  
**Structure:** Shared root module + one `.tfvars` per landing zone  
**State:** Azure Storage backend, one state file per LZ  
**CI/CD:** Plan on PR, apply on merge (managed by platform team)

### 2.3 GitHub Config Repo

**Repo:** `{org}/github-config` (placeholder — to be confirmed)  
**Agent:** `github-config` agent creates Terraform PRs here  
**CI/CD:** Managed via `cicd-workflow` agent output

### 2.4 Specialist Agents Available

| Agent | File | Capability | How This Orchestrator Uses It |
|---|---|---|---|
| `github-config` | `agents/github-config.agent.md` | Creates Terraform for GitHub resources (repos, teams, branch protection, environments, secrets) | Handoff: "Create repo X with these settings" |
| `cicd-workflow` | `agents/cicd-workflow.agent.md` | Generates GitHub Actions workflows for Terraform deployments | Handoff: "Create deploy workflow in repo X using reusable workflow pattern" |
| `terraform-module-creator` | `agents/terraform-module-creator.agent.md` | Creates/enhances private Terraform modules wrapping AVM | Not directly called by orchestrator; used separately to enhance the LZ vending module |

---

## 3. Agent Flow

This agent is invoked via a **structured prompt** — the user fills in defined inputs (workload name, environment, team, etc.) and the agent validates + orchestrates from there. The prompt serves as the entrypoint and intake form.

```
User invokes @alz-vending with structured prompt inputs:
  workload_name, environment, location, team_name, address_space, ...
          │
          ▼
┌─────────────────────────────────────────────────┐
│  Phase 0: Validate & Compute Defaults            │
│  Confirm inputs, derive naming, check for gaps   │
└──────────────────────┬──────────────────────────┘
                       │
          ▼                       ▼
┌──────────────────────┐ ┌────────────────────────┐
│  Phase 1A:            │ │  Phase 1B:              │
│  Create .tfvars PR    │ │  Create tracking issue   │
│  in ALZ infra repo    │ │  in ALZ infra repo       │
└──────────────────────┘ └────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  Phase 2: Handoff → github-config agent          │
│  "Create repo {name} with branch protection,     │
│   team access, environments, OIDC secrets"        │
│  (values may be placeholders until Phase 1 merges)│
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  Phase 3: Handoff → cicd-workflow agent           │
│  "Create deploy.yml in {repo} using reusable      │
│   workflow pattern with Azure OIDC auth"           │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  Phase 4: Track & Report                          │
│  Poll PR statuses via GitHub MCP                  │
│  Update tracking issue                            │
│  Notify user when LZ is ready with portal URLs    │
└─────────────────────────────────────────────────┘
```

---

## 4. Phase 0: Validate Prompt Inputs

### 4.1 Prompt Input Fields

The user invokes this agent via a structured prompt with defined inputs. The agent validates the supplied values, applies defaults for omitted optional fields, and asks follow-up questions only when required values are missing or invalid.

| Parameter | Question | Default | Required | Validation |
|---|---|---|---|---|
| `workload_name` | What is the workload/application name? | — | Yes | kebab-case, 3-30 chars, alphanumeric + hyphens |
| `workload_description` | Brief description? | — | No | Max 200 chars |
| `environment` | Production or DevTest? | `Production` | Yes | `Production` or `DevTest` |
| `location` | Primary Azure region? | `uksouth` | Yes | Valid Azure region |
| `address_space` | VNet CIDR block? | Ask user | Yes | Valid CIDR, /24 or larger |
| `hub_network_resource_id` | Hub VNet to peer with? | From config | Yes | Valid Azure resource ID |
| `team_name` | Owning GitHub team slug? | — | Yes | Must exist in GitHub org |
| `cost_center` | Cost center tag? | — | Yes | Non-empty string |
| `budget_amount` | Monthly budget (USD)? | `500` | No | Positive integer |
| `repo_name` | GitHub repo name? | `{workload_name}` | Yes | Valid GitHub repo name |
| `repo_visibility` | Repo visibility? | `internal` | Yes | `internal` or `private` |

### 4.2 Computed Values (Agent Derives)

```
subscription_alias_name     = "sub-{workload_name}-{env_short}"
subscription_display_name   = "{workload_name} ({environment})"
umi_name                    = "umi-{workload_name}-deploy"
umi_resource_group_name     = "rg-{workload_name}-identity"
github_org                  = from context / config
vnet_name                   = "vnet-{workload_name}-{location}"
```

---

## 5. Phase 1: Azure Subscription PR

### 5.1 What The Orchestrator Does

1. Generates a `.tfvars` file containing the **input parameter values** for the existing private LZ vending module
2. Creates a branch and PR in the ALZ infra repo via GitHub MCP
3. Creates a tracking issue in the same repo

This is **data generation, not Terraform code generation**. The orchestrator fills in parameter values for an existing module.

### 5.2 Target File

**Repo:** `{org}/alz-subscriptions`  
**File:** `landing-zones/{workload_name}.tfvars`  
**Branch:** `lz/{workload_name}`

### 5.3 Generated `.tfvars` Content

```hcl
# Landing Zone: {workload_name}
# Requested by: @{username}
# Date: {date}

# --- Subscription ---
subscription_alias_enabled                        = true
subscription_alias_name                           = "sub-{workload_name}-prod"
subscription_display_name                         = "{workload_name} (Production)"
subscription_workload                             = "Production"
subscription_management_group_association_enabled = true
subscription_management_group_id                  = "Corp"
location                                          = "uksouth"

subscription_tags = {
  workload     = "{workload_name}"
  environment  = "Production"
  team         = "{team_name}"
  cost_center  = "{cost_center}"
  managed_by   = "terraform"
  created_date = "{date}"
}

# --- Resource Groups ---
resource_group_creation_enabled = true
resource_groups = {
  rg_workload = {
    name     = "rg-{workload_name}"
    location = "uksouth"
  }
  rg_network = {
    name     = "NetworkWatcherRG"
    location = "uksouth"
  }
}

# --- Virtual Network (Corp = hub-peered) ---
virtual_network_enabled = true
virtual_networks = {
  spoke = {
    name                    = "vnet-{workload_name}-uksouth"
    resource_group_key      = "rg_workload"
    address_space           = ["{address_space}"]
    hub_peering_enabled     = true
    hub_network_resource_id = "{hub_network_resource_id}"
  }
}

# --- User Managed Identity + OIDC Federation ---
# NOTE: Requires UMI variables to be exposed in the private module wrapper.
# See prerequisite in ALZ_VENDING_AGENT_PLAN.md §2.1
#
# umi_enabled = true
# user_managed_identities = {
#   deploy = {
#     name               = "umi-{workload_name}-deploy"
#     resource_group_key = "rg_workload"
#     role_assignments = {
#       sub_contributor = {
#         definition     = "Contributor"
#         relative_scope = ""
#       }
#     }
#     federated_credentials_github = {
#       prod_env = {
#         organization = "{github_org}"
#         repository   = "{repo_name}"
#         entity       = "environment"
#         value        = "production"
#       }
#       main_branch = {
#         organization = "{github_org}"
#         repository   = "{repo_name}"
#         entity       = "branch"
#         value        = "main"
#       }
#       pull_request = {
#         organization = "{github_org}"
#         repository   = "{repo_name}"
#         entity       = "pull_request"
#       }
#     }
#   }
# }
```

### 5.4 PR Details

- **Branch:** `lz/{workload_name}`
- **Commit message:** `feat(lz): Add landing zone for {workload_name}`
- **PR title:** `feat(lz): Add landing zone — {workload_name}`
- **PR body:** Structured summary of all parameters, resources to be created, risk assessment
- **Labels:** `landing-zone`, `terraform`, `needs-review`
- **Draft:** `true`

### 5.5 Tracking Issue

Created in the ALZ infra repo alongside the PR:

```markdown
## 🏗️ Landing Zone Request: {workload_name}

| Field | Value |
|---|---|
| Workload | `{workload_name}` |
| Requested by | @{username} |
| Date | {date} |
| Environment | {environment} |
| Region | {location} |
| VNet CIDR | {address_space} |
| GitHub Repo | `{org}/{repo_name}` |

### Progress

- [x] Requirements gathered
- [ ] Phase 1: Azure subscription PR — #{pr_number}
- [ ] Phase 2: GitHub repo config — _(pending handoff to github-config agent)_
- [ ] Phase 3: Starter CI/CD workflow — _(pending handoff to cicd-workflow agent)_

### Outputs (populated after deployment)

| Output | Value |
|---|---|
| Subscription ID | _pending_ |
| Portal URL | _pending_ |
| UMI Client ID | _pending_ |
| GitHub Repo URL | _pending_ |
```

---

## 6. Phase 2: Handoff to github-config Agent

### 6.1 Strategy

The orchestrator issues a structured handoff to the existing `github-config` agent. This agent handles all Terraform generation for GitHub resources.

### 6.2 Handoff Prompt

The orchestrator constructs a detailed prompt for `github-config`:

```
Create GitHub configuration for a new workload repository:

**Repository:**
- Name: {repo_name}
- Organization: {github_org}
- Visibility: {repo_visibility}
- Description: "{workload_description}"
- Topics: ["azure", "terraform", "{workload_name}"]
- Delete branch on merge: true
- Allow squash merge: true (default)
- Allow merge commit: false
- Allow rebase merge: false

**Branch Protection (main):**
- Require pull request reviews: 1 approval minimum
- Require status checks: terraform-plan, lint
- Require up-to-date branches: true

**Team Access:**
- {team_name}: maintain
- platform-engineering: admin

**Environments:**
- production:
  - Required reviewers: {team_name}-leads
  - Deployment branch: main only
  - Secrets:
    - AZURE_CLIENT_ID = (value from LZ vending output — placeholder for now)
    - AZURE_TENANT_ID = {tenant_id}
    - AZURE_SUBSCRIPTION_ID = (value from LZ vending output — placeholder for now)

**Target repo for Terraform PR:** {org}/github-config
```

### 6.3 Dependency on Phase 1

Phase 2 needs the `subscription_id` and `umi_client_id` from Phase 1's apply output. Options:

| Approach | When | How |
|---|---|---|
| **Placeholder values** | Phase 1 PR not yet merged | Create Phase 2 PR with `"PENDING_SUBSCRIPTION_APPLY"` placeholders; label `blocked:waiting-for-subscription` |
| **Real values** | Phase 1 PR merged + applied | Orchestrator reads Terraform outputs (from pipeline artifacts, PR comments, or state); updates Phase 2 PR with real values; removes `blocked` label |
| **Deferred handoff** | User preference | Orchestrator waits to trigger Phase 2 until Phase 1 is fully deployed |

Recommend: **Placeholder approach** — create both PRs immediately so reviewers can see the full picture, then update later.

---

## 7. Phase 3: Handoff to cicd-workflow Agent

### 7.1 Strategy

After Phase 2 creates the repo, hand off to `cicd-workflow` to generate a deploy workflow in the new repo.

### 7.2 Handoff Prompt

```
Create a GitHub Actions deployment workflow for a new Azure workload repo:

**Repository:** {org}/{repo_name}
**Provider:** azurerm (Azure OIDC authentication)
**Pattern:** Child workflow consuming a reusable parent workflow

The workflow should:
- Call a reusable workflow at {org}/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
- Pass inputs: environment, terraform-version, working-directory, azure-region
- Pass secrets: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
- Trigger on: push to main, pull_request to main

If the reusable parent workflow doesn't exist yet, create a standalone
workflow with the standard Terraform plan-on-PR / apply-on-merge pattern
using Azure OIDC auth. Document that it should be migrated to the reusable
pattern when the parent workflow becomes available.
```

### 7.3 Timing

This handoff happens **after** Phase 2 completes (repo must exist first). The cicd-workflow agent creates a PR in the new workload repo.

---

## 8. Phase 4: Track & Report

### 8.1 Status Checking

When the user asks "what's the status of my landing zone?", the orchestrator:

1. Finds the tracking issue by searching for issues with label `landing-zone` and title containing `{workload_name}`
2. Checks each PR status via GitHub MCP (`pull_request_read` → `get`, `get_status`)
3. Determines overall state:

| State | Condition | User Message |
|---|---|---|
| `awaiting-review` | Phase 1 PR open, no reviews | "Your LZ request is awaiting Platform Engineering review" |
| `in-review` | Phase 1 PR has review comments | "Platform Engineering is reviewing your LZ request" |
| `deploying` | Phase 1 PR merged, pipeline running | "Your subscription is being provisioned..." |
| `partially-ready` | Phase 1 complete, Phase 2 pending | "Subscription ready! GitHub repo config pending review" |
| `ready` | All phases complete | Full completion notification (see §8.2) |
| `blocked` | PR has changes requested or failing checks | "Action needed: {details}" |

### 8.2 Completion Notification

```markdown
## ✅ Landing Zone Ready: {workload_name}

### Azure Resources
- **Subscription:** {subscription_display_name}
  - [View in Azure Portal](https://portal.azure.com/#@{tenant}/resource/subscriptions/{subscription_id}/overview)
- **Resource Groups:** rg-{workload_name}, NetworkWatcherRG
- **VNet:** vnet-{workload_name}-{location} ({address_space}) — peered with hub

### GitHub Resources
- **Repository:** [{org}/{repo_name}](https://github.com/{org}/{repo_name})
  - Branch protection: ✅ Configured
  - Environment: ✅ production (with required reviewers)
  - OIDC Auth: ✅ Configured

### Getting Started
1. Clone: `git clone https://github.com/{org}/{repo_name}.git`
2. Push to a feature branch → PR → automatic `terraform plan`
3. Merge to main → deploys to production (after environment approval)

### Tracking
- Issue: #{issue_number}
- Phase 1 PR: #{phase1_pr} ✅
- Phase 2 PR: #{phase2_pr} ✅
- Phase 3 PR: #{phase3_pr} ✅
```

---

## 9. Agent Definition Design

### 9.1 YAML Frontmatter

```yaml
---
name: ALZ Subscription Vending
description: Self-service Azure Landing Zone provisioning — orchestrates subscription creation, GitHub repo config, and CI/CD setup via specialist agents
argument-hint: "Provide: workload_name, environment (Production/DevTest), location, team_name, address_space (CIDR), cost_center. Optional: repo_name, repo_visibility, budget_amount, workload_description"
tools:
  ['read', 'search', 'fetch/*', 'github/*']
agents: ["github-config", "cicd-workflow"]
mcp-servers:
  github-mcp-server:
    type: http
    url: https://api.githubcopilot.com/mcp/
    tools: ["*"]
    headers:
      X-MCP-Toolsets: all
handoffs:
  - label: "Configure GitHub Repository"
    agent: github-config
    prompt: "{structured_github_requirements}"
    send: true
  - label: "Create CI/CD Workflow"
    agent: cicd-workflow
    prompt: "{structured_cicd_requirements}"
    send: true
---
```

**Prompt entrypoint example:**
```
@alz-vending workload_name: payments-api, environment: Production, location: uksouth,
team_name: payments-team, address_space: 10.100.0.0/24, cost_center: CC-4521
```

The agent parses these inputs, applies defaults (e.g. `repo_name` defaults to `workload_name`, `budget_amount` defaults to `500`), validates, and proceeds through phases without further prompting unless values are missing or invalid.

**Tool selection rationale (orchestrator-only):**
- `read` — Read local config/instruction files
- `search` — Find files in workspace
- `fetch/*` — Fetch Azure docs if needed for answering user questions
- `github/*` — Create branches, push `.tfvars` files, create PRs/issues, poll PR status
- **No `execute`** — Orchestrator doesn't run Terraform; specialist agents do
- **No `edit`** — Orchestrator doesn't modify code in workspace; it pushes to remote repos
- **No `terraform` MCP** — Orchestrator doesn't look up Terraform docs; it generates parameter values

### 9.2 Instruction Body Structure

1. **Identity** — "You are an Azure Landing Zone vending orchestrator that coordinates self-service subscription provisioning."
2. **Scope** — "You generate `.tfvars` data files and orchestrate specialist agents. You do NOT write Terraform modules, CI/CD workflows, or GitHub configuration code."
3. **Phase 0** — Requirements gathering with intake questions, defaults, validation
4. **Phase 1** — `.tfvars` generation, branch + PR creation via GitHub MCP, tracking issue creation
5. **Phase 2** — Handoff prompt template for `github-config` agent
6. **Phase 3** — Handoff prompt template for `cicd-workflow` agent
7. **Phase 4** — PR status tracking, issue updating, completion notification
8. **Configuration** — Org-specific values (repo names, billing scope, hub VNet ID, tenant ID, etc.)
9. **Status checking** — How to respond when user asks "what's the status?"

---

## 10. Configuration Block

The agent needs these org-specific values embedded in its instructions (or in a referenced config file):

```yaml
# --- ALZ Vending Configuration ---
github_org: "nathlan"
alz_infra_repo: "alz-subscriptions"          # Repo with LZ tfvars + shared root module
github_config_repo: "github-config"           # Repo with GitHub Terraform config
reusable_workflow_repo: ".github-workflows"   # Repo with shared GHA workflows (future)

# Azure
tenant_id: "PLACEHOLDER"
billing_scope: "PLACEHOLDER"
default_location: "uksouth"
default_management_group: "Corp"
hub_network_resource_id: "PLACEHOLDER"

# State
state_resource_group: "rg-terraform-state"
state_storage_account: "stterraformstate"
state_container: "alz-subscriptions"

# Defaults
default_budget: 500
default_environment: "Production"
default_repo_visibility: "internal"
platform_team: "platform-engineering"

# Private module
lz_module_repo: "nathlan/terraform-azurerm-landing-zone-vending"
lz_module_version: "~> 1.0"
```

---

## 11. Prerequisites & Dependencies

### Must be in place before this agent is useful:

| # | Prerequisite | Status | Owner |
|---|---|---|---|
| 1 | Private LZ vending module exists | ✅ Done | `terraform-module-creator` |
| 2 | LZ module exposes UMI + federated credentials variables | ❌ Needed | `terraform-module-creator` |
| 3 | LZ module exposes budget variables | ❌ Needed | `terraform-module-creator` |
| 4 | ALZ infra repo exists with root module consuming private wrapper | ❌ Needed | Platform team / agent |
| 5 | ALZ infra repo has CI/CD pipeline (plan on PR, apply on merge) | ❌ Needed | `cicd-workflow` agent |
| 6 | GitHub config repo exists | ✅ Done | `github-config` agent |
| 7 | GitHub config repo has CI/CD pipeline | ✅ Done | `cicd-workflow` agent |
| 8 | `github-config` agent accepts inbound handoff prompts | ✅ Has `inbound-prompts` | — |
| 9 | `cicd-workflow` agent accepts inbound handoff prompts | ✅ Available via handoff | — |

### Enhancement needed for private module (task for terraform-module-creator):

Add pass-through variables to `nathlan/terraform-azurerm-landing-zone-vending`:

```hcl
# New variables needed in the private wrapper:
variable "umi_enabled" { ... }
variable "user_managed_identities" { ... }
variable "budget_enabled" { ... }
variable "budgets" { ... }
```

And corresponding pass-through in `main.tf` and outputs in `outputs.tf`:

```hcl
# In main.tf - add to module call:
umi_enabled             = var.umi_enabled
user_managed_identities = var.user_managed_identities
budget_enabled          = var.budget_enabled
budgets                 = var.budgets

# In outputs.tf - add:
output "umi_client_ids" { ... }
output "umi_principal_ids" { ... }
```

---

## 12. Implementation Tasks

| # | Task | Type | Complexity | Notes |
|---|---|---|---|---|
| 1 | Create `agents/alz-vending.agent.md` frontmatter | Agent definition | Low | Tools, MCP servers, handoffs |
| 2 | Write Phase 0: Requirements gathering instructions | Agent definition | Medium | Intake questions, defaults, validation rules |
| 3 | Write Phase 1: `.tfvars` template + PR creation | Agent definition | Medium | Template with placeholders, GitHub MCP usage |
| 4 | Write Phase 2: `github-config` handoff prompt template | Agent definition | Low | Structured prompt with all repo settings |
| 5 | Write Phase 3: `cicd-workflow` handoff prompt template | Agent definition | Low | Structured prompt for reusable workflow pattern |
| 6 | Write Phase 4: Tracking & status reporting | Agent definition | Medium | Issue template, PR polling logic, completion notification |
| 7 | Write configuration section | Agent definition | Low | Org-specific values with placeholders |
| 8 | Enhance private LZ module (UMI + budget variables) | Module enhancement | Medium | Task for `terraform-module-creator` agent |
| 9 | Create/verify ALZ infra repo structure | Repo setup | Medium | Root module + tfvars pattern + CI/CD |
| 10 | End-to-end test with sample request | Testing | High | Full flow through all phases |

**Task 1-7** = the agent definition file itself  
**Task 8** = separate task for `terraform-module-creator`  
**Task 9-10** = integration work  

---

## 13. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Phase 2 PR created before Phase 1 outputs are known | Use placeholder values; update after Phase 1 apply; label `blocked` |
| Private module doesn't expose UMI variables yet | Agent generates UMI section as comments in `.tfvars`; notes prerequisite |
| VNet CIDR overlap | Orchestrator reads existing `.tfvars` files in ALZ repo to detect conflicts |
| Agent generates invalid `.tfvars` | Agent uses known variable schema from private module; platform CI/CD validates on PR |
| Handoff to specialist agent fails | Orchestrator provides structured prompt; user can manually invoke specialist agent |
| User asks for status but tracking issue doesn't exist | Orchestrator searches PRs by branch name `lz/{workload_name}` as fallback |

---

## 14. Future Enhancements

1. **Additional LZ product lines** — Online (no hub peering), Sandbox (isolated), Data (private endpoints)
2. **IPAM integration** — Auto-assign CIDR from IP Address Management
3. **Auto-approve sandbox** — Skip manual approval for non-production LZs
4. **Decommission flow** — Reverse agent that removes LZ resources
5. **Cost reporting** — Pull Azure Cost Management data into tracking issue
6. **App-repo GitHub settings merge** — Let users define GitHub settings as Terraform in their app LZ repo (e.g. extra branch protection rules, additional teams). The org-level parent CI/CD workflow merges/overwrites these with org defaults, giving teams customization within guardrails
7. **GitHub Copilot coding agent trigger** — Auto-run from GitHub Issue templates
