# ALZ Vending Agent - Verbose Debugging Report

**Generated:** 2026-02-09
**Status:** 🔴 Multiple Critical Issues Found

This document provides a comprehensive analysis of issues preventing the ALZ Vending orchestrator agent from functioning correctly.

---

## Executive Summary

The ALZ Vending agent has been designed but **cannot function in its current state** due to:

1. **Missing critical repository** (`alz-subscriptions`)
2. **Unconfigured placeholder values** (Azure tenant ID, billing scope, hub network)
3. **Missing reusable workflow repository**
4. **Module feature gaps** (UMI/OIDC, budgets)

The agent is well-designed architecturally but requires infrastructure setup before it can be operationally tested.

---

## Critical Issues (Blockers)

### 🔴 Issue #1: Missing Primary Infrastructure Repository

**Problem:**
- Agent configuration references: `alz_infra_repo: "alz-subscriptions"`
- Repository `nathlan/alz-subscriptions` **does not exist**
- This is the core repository where all landing zone `.tfvars` files should be stored

**Impact:**
- Phase 0 validation **fails** - cannot check for duplicate workload names
- Phase 0 validation **fails** - cannot scan for CIDR overlaps
- Phase 1 **cannot create branch** - target repository doesn't exist
- Phase 1 **cannot push .tfvars file** - no repository to push to
- Phase 1 **cannot create PR** - no target repository
- Phase 1 **cannot create tracking issue** - no issue tracker

**What the agent tries to do:**
```yaml
# From agents/alz-vending.agent.md Line 427
alz_infra_repo: "alz-subscriptions"

# Phase 1 Instructions (Line 91-93):
1. Read existing `.tfvars` files in the ALZ infra repo to understand the established pattern:
   Use GitHub MCP → get_file_contents on {alz_infra_repo} to read an existing .tfvars file
```

**Verification:**
```bash
# GitHub search confirms repo does not exist
$ gh repo list nathlan --limit 100 | grep alz-subscriptions
# No results
```

**Fix Required:**
1. Create repository `nathlan/alz-subscriptions`
2. Initialize with:
   - `main` branch
   - `.gitignore` for Terraform (`.terraform/`, `*.tfstate`, etc.)
   - `landing-zones/` directory for `.tfvars` files
   - At least one example `.tfvars` file (e.g., `landing-zones/example-workload.tfvars`)
   - `README.md` explaining the repo structure
   - GitHub Actions workflow for Terraform plan/apply
   - Branch protection on `main`

**Example Repository Structure:**
```
alz-subscriptions/
├── .github/
│   └── workflows/
│       └── terraform-apply.yml
├── landing-zones/
│   ├── example-app-prod.tfvars
│   └── example-api-dev.tfvars
├── .gitignore
├── .terraform-version
├── backend.tf       # Azure Storage backend config
├── main.tf          # Calls terraform-azurerm-landing-zone-vending module
├── variables.tf
└── README.md
```

---

### 🔴 Issue #2: Unconfigured Azure Tenant/Billing Information

**Problem:**
Configuration contains three PLACEHOLDER values that are required for generating valid `.tfvars` files:

```yaml
# From agents/alz-vending.agent.md Line 433-437
# --- Azure ---
tenant_id: "PLACEHOLDER"                  # ❌ Required for OIDC federation
billing_scope: "PLACEHOLDER"              # ❌ Required for subscription creation
hub_network_resource_id: "PLACEHOLDER"    # ❌ Required for VNet peering
```

**Impact:**

1. **`tenant_id` Missing:**
   - Phase 2 GitHub repo secrets will have invalid/placeholder tenant ID
   - OIDC authentication to Azure will fail
   - Workload repositories cannot deploy to Azure
   - `.tfvars` template references this value (Line 175 in agent instructions)

2. **`billing_scope` Missing:**
   - Cannot generate subscription creation configuration
   - The private module requires `subscription_billing_scope` variable
   - Subscription vending will fail during Terraform apply

3. **`hub_network_resource_id` Missing:**
   - Cannot configure hub-spoke VNet peering
   - Corp Landing Zones require connectivity to hub VNet
   - `.tfvars` template includes: `hub_network_resource_id = "{hub_network_resource_id}"`

**What the agent tries to do:**
```hcl
# From .tfvars template (Line 157):
virtual_networks = {
  spoke = {
    name                    = "vnet-{workload_name}-{location}"
    resource_group_key      = "rg_workload"
    address_space           = ["{address_space}"]
    hub_peering_enabled     = true
    hub_network_resource_id = "{hub_network_resource_id}"  # Uses placeholder!
  }
}
```

**Fix Required:**

1. **Get Real Azure Values:**
   ```bash
   # Tenant ID
   az account show --query tenantId -o tsv

   # Billing Scope (Enterprise Agreement example)
   az billing enrollment-account list --query "[0].id" -o tsv
   # Format: /providers/Microsoft.Billing/billingAccounts/{id}/enrollmentAccounts/{id}

   # Hub VNet Resource ID
   az network vnet show \
     --resource-group rg-hub-network \
     --name vnet-hub-uksouth \
     --query id -o tsv
   # Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}
   ```

2. **Update Configuration:**
   Edit `agents/alz-vending.agent.md` lines 433-437 with actual values.

3. **Security Consideration:**
   These values are **not secrets** but are **environment-specific identifiers**:
   - `tenant_id`: Public, appears in OIDC URLs
   - `billing_scope`: Internal identifier, not sensitive
   - `hub_network_resource_id`: Internal identifier, not sensitive

---

### 🔴 Issue #3: Missing Reusable Workflows Repository

**Problem:**
- Agent configuration references: `reusable_workflow_repo: ".github-workflows"`
- Repository `nathlan/.github-workflows` **does not exist**
- Phase 3 handoff to `cicd-workflow` agent expects this repo

**Impact:**
- Phase 3 handoff prompt includes: "Call a reusable workflow at {github_org}/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main"
- `cicd-workflow` agent will fail to find the parent workflow
- Agent instructions correctly document fallback: "If the reusable parent workflow doesn't exist yet, create a standalone workflow..."
- But this creates inconsistency across workload repos

**What the agent tries to do:**
```markdown
# From Phase 3 handoff prompt (Line 315):
The workflow should:
- Call a reusable workflow at {github_org}/.github-workflows/.github/workflows/azure-terraform-deploy.yml@main
```

**Verification:**
```bash
# GitHub search confirms repo does not exist
$ gh repo list nathlan --limit 100 | grep github-workflows
# No results
```

**Fix Options:**

**Option A: Create Reusable Workflow Repo (Recommended)**
1. Create repository `nathlan/.github-workflows`
2. Add `.github/workflows/azure-terraform-deploy.yml` with reusable workflow
3. Include inputs: `environment`, `terraform-version`, `working-directory`, `azure-region`
4. Include secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
5. Implement standard plan-on-PR / apply-on-merge pattern

**Option B: Update Agent to Use Per-Repo Workflows**
1. Change `cicd-workflow` handoff to always create standalone workflows
2. Document that migration to reusable pattern is future work
3. Accept some duplication across repos

**Recommendation:** Option A for maintainability and DRY principles.

---

## High-Priority Issues (Functional Degradation)

### 🟠 Issue #4: Module Feature Gaps - UMI and Budget Variables

**Problem:**
The private wrapper module `nathlan/terraform-azurerm-landing-zone-vending` does not expose variables for:
- User Managed Identity (UMI) creation
- Federated credentials for OIDC
- Budget management

**Current Module Variables (from MODULE_TRACKING.md):**
```hcl
✅ subscription_alias_enabled
✅ subscription_display_name
✅ subscription_workload
✅ subscription_management_group_id
✅ subscription_tags
✅ resource_group_creation_enabled
✅ resource_groups
✅ virtual_network_enabled
✅ virtual_networks
✅ role_assignment_enabled

❌ umi_enabled                    # NOT exposed
❌ user_managed_identities        # NOT exposed
❌ budget_enabled                 # NOT exposed
❌ budgets                        # NOT exposed
```

**Impact:**
- Phase 1 `.tfvars` includes commented-out UMI section with note: "Requires UMI variables to be exposed in the private module wrapper"
- Workload identity federation (OIDC) setup is **manual** instead of automated
- Budgets must be configured manually after subscription creation
- Reduces automation value proposition

**What the agent tries to do:**
```hcl
# From .tfvars template (Lines 165-189) - COMMENTED OUT:
# NOTE: Requires UMI variables to be exposed in the private module wrapper.
# See: https://github.com/nathlan/terraform-azurerm-landing-zone-vending
# Once the module supports UMI, uncomment and update this section.
#
# umi_enabled = true
# user_managed_identities = {
#   deploy = {
#     name               = "umi-{workload_name}-deploy"
#     resource_group_key = "rg_workload"
#     role_assignments = { ... }
#     federated_credentials_github = { ... }
#   }
# }
```

**Fix Required:**

1. **Use `terraform-module-creator` Agent:**
   Invoke the terraform-module-creator agent to enhance the private module:
   ```
   @terraform-module-creator

   Enhance the nathlan/terraform-azurerm-landing-zone-vending module to expose:

   1. User Managed Identity variables (pass-through to underlying AVM module):
      - umi_enabled (bool)
      - user_managed_identities (map of UMI configs)

   2. Budget variables:
      - budget_enabled (bool)
      - budgets (map of budget configs)

   Follow the existing pattern of pass-through variables used for virtual_networks
   and resource_groups. Ensure proper validation and documentation.
   ```

2. **Update Agent Template:**
   After module enhancement, uncomment the UMI section in the `.tfvars` template.

**Workaround:**
Agent currently documents this as a known limitation and includes commented template for future use.

---

### 🟠 Issue #5: Team Validation Capability Unknown

**Problem:**
Phase 0 validation step #3 states:
> "Verify `team_name` exists in the GitHub org using GitHub MCP (`get_team_members` or similar)"

**Issue:**
- GitHub MCP server tool availability not fully documented
- Agent instructions assume team lookup capability exists
- If capability doesn't exist, validation step will fail

**Impact:**
- Agent may attempt to create repo with team access for non-existent team
- GitHub API will reject the configuration
- Better to fail early during validation than during Phase 2

**Fix Required:**

1. **Verify GitHub MCP Capabilities:**
   Test if GitHub MCP server supports team operations:
   ```javascript
   // Expected operation
   github-mcp-server.list_teams(owner: "nathlan")
   github-mcp-server.get_team(owner: "nathlan", team_slug: "platform-engineering")
   ```

2. **Update Validation Logic:**
   If team lookup not available:
   - Remove validation step
   - Document assumption that user must provide valid team name
   - Let GitHub API return error during Phase 2 if team invalid

3. **Add to Error Handling:**
   Document what happens if Phase 2 fails due to invalid team name.

---

### 🟠 Issue #6: Platform Team Assumption Not Validated

**Problem:**
Agent configuration assumes team exists:
```yaml
platform_team: "platform-engineering"
```

Phase 2 handoff includes:
```markdown
**Team Access:**
- {team_name}: maintain
- platform-engineering: admin
```

**Impact:**
- If `platform-engineering` team doesn't exist, Phase 2 github-config agent will fail
- No validation during Phase 0 to confirm team exists
- Consistent with Issue #5 (team validation)

**Fix Required:**
Same as Issue #5 - validate platform team exists or document assumption.

---

## Medium-Priority Issues (UX/Operational)

### 🟡 Issue #7: No Graceful Handling for Missing Repositories

**Problem:**
Agent validation logic (Phase 0) attempts to:
1. Read existing `.tfvars` files from `alz-subscriptions` repo
2. Scan for duplicate workload names
3. Scan for CIDR overlaps

If repo doesn't exist, GitHub MCP operations will fail with errors, not graceful messages.

**Impact:**
- Poor error messages: "Repository not found" instead of helpful guidance
- User doesn't know what's wrong or how to fix it
- Agent appears broken rather than unconfigured

**Fix Required:**

Add pre-flight check in Phase 0:
```markdown
### Phase 0: Pre-flight Checks

Before validation:
1. Verify `alz-subscriptions` repository exists
   - If NOT: Display error message with setup instructions
   - Include link to infrastructure setup documentation
   - Stop execution with actionable error

2. Verify `github-config` repository exists
   - If NOT: Warn that Phase 2 will fail
   - Offer to proceed with Phase 1 only

3. Verify `.github-workflows` repository exists
   - If NOT: Warn that Phase 3 will use standalone workflow
   - Document migration path
```

**Suggested Error Message:**
```
❌ ALZ Infrastructure Not Configured

The ALZ Vending agent requires the following repository to be set up:
  • nathlan/alz-subscriptions

This repository should contain:
  ✓ Terraform configuration calling terraform-azurerm-landing-zone-vending module
  ✓ landing-zones/ directory for .tfvars files
  ✓ GitHub Actions workflow for Terraform apply
  ✓ At least one example .tfvars file

Please create this repository before using the vending agent.
See: ALZ_VENDING_AGENT_PLAN.md Section 2.2 for details.
```

---

### 🟡 Issue #8: Validation Order Dependencies

**Problem:**
Current validation flow (Phase 0, steps 1-6):
1. Confirm workload_name format ✅ (local validation)
2. Confirm address_space format ✅ (local validation)
3. Verify team exists ⚠️ (requires GitHub API)
4. Check for duplicate .tfvars ❌ (requires alz-subscriptions repo)
5. Scan for CIDR overlaps ❌ (requires alz-subscriptions repo)
6. Present summary and confirm ✅

Steps 4-5 cannot complete without the infrastructure repo.

**Impact:**
- Agent fails during validation rather than pre-flight
- Harder to troubleshoot vs. explicit pre-flight check

**Fix Required:**
Move repo existence check before validation (see Issue #7).

---

### 🟡 Issue #9: No Dry-Run Mode

**Problem:**
Agent immediately starts creating resources (branches, PRs, issues) after validation.
No way to test validation logic without side effects.

**Impact:**
- Difficult to test agent behavior
- Cannot safely demonstrate to stakeholders
- Testing pollutes real infrastructure

**Fix Required:**

Add `--dry-run` flag support:
```markdown
## Invocation Options

**Standard mode:**
@alz-vending workload_name: test-app, environment: Production, ...

**Dry-run mode (validation only):**
@alz-vending --dry-run workload_name: test-app, environment: Production, ...

In dry-run mode:
- Performs all validation (name format, CIDR, duplicates, overlaps)
- Shows exactly what would be created (branch, PR, issue)
- Does NOT create any resources
- Outputs structured summary of planned actions
```

---

## Low-Priority Issues (Polish)

### 🟢 Issue #10: Agent Handoff Agent Name Mismatch

**Problem:**
Agent YAML frontmatter defines:
```yaml
agents: ["GitHub Configuration Agent", "CI/CD Workflow Agent"]
```

But agent files are named:
- `github-config.agent.md` → Name in file: "GitHub Configuration Agent" ✅
- `cicd-workflow.agent.md` → Name in file: "CI/CD Workflow Agent" ✅

This is actually **correct** - no issue here. The agent names match.

**Status:** ✅ Not an issue

---

### 🟢 Issue #11: Handoff Button Configuration

**Problem:**
Handoff buttons use `send: false`:
```yaml
handoffs:
  - label: "Configure GitHub Repository"
    agent: GitHub Configuration Agent
    prompt: "Create GitHub configuration..."
    send: false  # User must click to send
```

**Impact:**
- User must manually trigger handoffs
- Not fully automated end-to-end

**Consideration:**
This might be **intentional** - allows user to review/modify handoff prompts before sending.

**Recommendation:**
- Keep `send: false` for now (allows user control)
- Document in instructions that user should click handoff buttons
- Consider adding `send: true` option for fully automated mode

---

## Summary Table

| Issue | Severity | Blocks Agent | Fix Complexity | Owner |
|-------|----------|--------------|----------------|-------|
| #1: Missing alz-subscriptions repo | 🔴 Critical | Yes | Medium | Platform Team |
| #2: PLACEHOLDER configuration values | 🔴 Critical | Yes | Low | Platform Team |
| #3: Missing .github-workflows repo | 🔴 Critical | Partial | Medium | Platform Team |
| #4: Module UMI/budget variables | 🟠 High | Partial | Medium | terraform-module-creator agent |
| #5: Team validation capability | 🟠 High | No | Low | Agent Developer |
| #6: Platform team assumption | 🟠 High | No | Low | Platform Team |
| #7: No graceful error handling | 🟡 Medium | No | Low | Agent Developer |
| #8: Validation order dependencies | 🟡 Medium | No | Low | Agent Developer |
| #9: No dry-run mode | 🟡 Medium | No | Medium | Agent Developer |
| #10: Agent name mismatch | 🟢 Low | No | N/A | None (not an issue) |
| #11: Handoff button config | 🟢 Low | No | Low | Agent Developer |

---

## Remediation Roadmap

### Phase 1: Unblock Agent (Critical - Do First)

**Goal:** Make agent operational for basic testing

1. **Create `alz-subscriptions` repository** [Platform Team, 2-4 hours]
   - Initialize with Terraform configuration
   - Add example `.tfvars` files
   - Set up basic GitHub Actions workflow
   - Configure branch protection

2. **Populate PLACEHOLDER values** [Platform Team, 30 minutes]
   - Get Azure tenant ID
   - Get billing scope from Azure EA/MCA
   - Get hub VNet resource ID
   - Update `agents/alz-vending.agent.md` config section

3. **Create `.github-workflows` repository** [Platform Team, 2-3 hours]
   - Create reusable Azure Terraform deploy workflow
   - Document inputs and secrets
   - Test with sample repository

**Outcome:** Agent can execute end-to-end (Phase 0 → Phase 1 → Phase 2 → Phase 3)

### Phase 2: Enhance Reliability (High Priority)

**Goal:** Make agent production-ready

4. **Enhance private module** [terraform-module-creator agent, 1-2 hours]
   - Add UMI pass-through variables
   - Add budget pass-through variables
   - Update module version

5. **Add pre-flight checks** [Agent Developer, 1 hour]
   - Verify repositories exist before validation
   - Provide helpful error messages
   - Document setup requirements

6. **Verify team validation** [Agent Developer, 30 minutes]
   - Test GitHub MCP team lookup capabilities
   - Update validation logic accordingly
   - Document team validation assumptions

**Outcome:** Agent handles errors gracefully, supports full automation

### Phase 3: Improve UX (Medium Priority)

**Goal:** Make agent easier to use and test

7. **Add dry-run mode** [Agent Developer, 1 hour]
   - Parse `--dry-run` flag
   - Execute validation without side effects
   - Output structured plan

8. **Improve error messages** [Agent Developer, 1 hour]
   - Context-aware error messages
   - Actionable remediation steps
   - Links to documentation

**Outcome:** Agent is user-friendly and testable

### Phase 4: Polish (Low Priority)

9. **Documentation updates**
   - Add troubleshooting guide
   - Add operator runbook
   - Add user quickstart guide

10. **Consider automated handoffs**
    - Evaluate changing `send: false` to `send: true`
    - Document trade-offs
    - Gather user feedback

---

## Testing Strategy

### Unit Testing (Phase 0 Validation)

**Can test NOW (no dependencies):**
- Workload name format validation
- CIDR format validation
- Environment value validation
- Computed value derivation

**Test cases:**
```bash
# Valid inputs
workload_name: "payments-api"      ✅
environment: "Production"           ✅
address_space: "10.100.0.0/24"     ✅

# Invalid inputs
workload_name: "Payments_API"      ❌ (uppercase, underscore)
workload_name: "pa"                ❌ (too short)
workload_name: "a-very-long-name-that-exceeds-thirty-chars" ❌ (too long)
environment: "Staging"              ❌ (not Production or DevTest)
address_space: "10.100.0.0/25"     ❌ (too small, requires /24 or larger)
address_space: "invalid"            ❌ (not CIDR format)
```

### Integration Testing (Phase 1)

**Requires:**
- ✅ `alz-subscriptions` repository created
- ✅ PLACEHOLDER values populated

**Test cases:**
1. Create branch in alz-subscriptions
2. Push `.tfvars` file with valid content
3. Create draft PR with correct labels
4. Create tracking issue
5. Verify PR description includes all expected sections

### End-to-End Testing (All Phases)

**Requires:**
- ✅ All critical issues resolved
- ✅ `github-config` repository operational
- ✅ `.github-workflows` repository operational
- ✅ Private module enhanced (optional, will use commented template)

**Test scenario:**
```
Input:
  workload_name: test-app-001
  environment: DevTest
  location: uksouth
  team_name: test-team
  address_space: 10.200.0.0/24
  cost_center: CC-TEST-001

Expected Outputs:
  1. Branch created: lz/test-app-001
  2. File created: landing-zones/test-app-001.tfvars
  3. PR created in alz-subscriptions
  4. Issue created in alz-subscriptions
  5. Handoff to github-config (creates PR in github-config)
  6. Handoff to cicd-workflow (creates PR in test-app-001 repo)
  7. Status tracking returns accurate state
```

---

## Next Steps

**For Platform Team:**
1. Review this diagnostic report
2. Prioritize fixes based on your rollout timeline
3. Create `alz-subscriptions` repository (Issue #1)
4. Populate configuration values (Issue #2)
5. Create `.github-workflows` repository (Issue #3)

**For Agent Developer:**
6. Add pre-flight checks (Issue #7)
7. Verify team validation (Issue #5)
8. Add dry-run mode (Issue #9)

**For Module Developer:**
9. Invoke `terraform-module-creator` agent to enhance module (Issue #4)

**For Testing:**
10. Start with unit tests for validation logic
11. Progress to integration tests when repos are ready
12. Complete with end-to-end test scenario

---

## Conclusion

The ALZ Vending orchestrator agent is **well-designed** but currently **non-operational** due to missing infrastructure dependencies. The agent itself requires minimal changes - the primary work is setting up the supporting repositories and configuration.

**Estimated Total Effort:**
- Critical issues (unblock): **4-7 hours**
- High priority (production-ready): **2-3 hours**
- Medium priority (UX): **2 hours**
- Total: **8-12 hours** of work

**Risk Assessment:**
- Low risk: Infrastructure setup is straightforward
- Medium risk: Module enhancement (delegated to agent)
- Low risk: Agent code changes (minimal, well-scoped)

**Recommended Approach:**
Start with Phase 1 remediation to unblock testing, then iterate on reliability and UX improvements based on user feedback.

---

**Document Version:** 1.0
**Last Updated:** 2026-02-09
**Status:** Ready for Platform Team review
