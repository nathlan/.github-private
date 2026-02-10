# ALZ Workload Template Configuration - Agent Delegation

**Date:** 2026-02-10  
**Pattern:** ALZ Vending Orchestrator → GitHub Config Specialist Agent  
**Status:** ✅ PR Created in github-config Repository

---

## Objective

Configure the `nathlan/alz-workload-template` repository using Terraform infrastructure-as-code, following the ALZ agent delegation pattern where:
- **Reusable Azure workflows** exist in `nathlan/.github-workflows` (parent workflows)
- **Template repository** contains only child workflows that call the parent
- **Configuration is managed via Terraform** in the `nathlan/github-config` repository

---

## Implementation Approach

### ALZ Orchestrator Pattern

As the ALZ vending orchestrator, I delegated the Terraform generation to the github-config specialist agent:

1. **Orchestrator Role (ALZ Vending):**
   - Understood the requirement
   - Structured the handoff prompt
   - Invoked the github-config agent
   - Documented the outcome

2. **Specialist Role (GitHub Config Agent):**
   - Generated complete Terraform IaC
   - Created isolated workspace in `/tmp/`
   - Validated configuration (init, fmt, validate)
   - Created PR in target repository

3. **Separation of Concerns:**
   - Orchestrator doesn't write Terraform code
   - Specialist agent handles all IaC generation
   - Changes go through human-reviewed PRs

---

## What Was Created

### Pull Request in github-config Repository

**PR Details:**
- **Repository:** nathlan/github-config
- **PR Number:** #11
- **Branch:** terraform/github-config-alz-workload-template
- **Status:** Draft (awaiting review)
- **URL:** https://github.com/nathlan/github-config/pull/11

### Terraform Configuration

**Files Generated (12 total, 571 lines):**

```
github-config/
├── terraform/
│   ├── main.tf                    # Resource definitions (151 lines)
│   ├── variables.tf               # Input variables (56 lines)
│   ├── outputs.tf                 # Output values (48 lines)
│   ├── versions.tf                # Version constraints (9 lines)
│   ├── providers.tf               # Provider config (4 lines)
│   ├── data.tf                    # Data sources (17 lines)
│   ├── .gitignore                 # Terraform ignores (31 lines)
│   ├── .terraform.lock.hcl        # Provider lock (20 lines)
│   └── README.md                  # Documentation (235 lines)
└── .handover/
    └── alz-workload-template-config.md  # CI/CD integration docs (166 lines)
```

---

## Repository Configuration

### Critical Settings

**Template Repository Flag:**
- `is_template = true` - **ESSENTIAL**
- Enables "Use this template" button
- Core to ALZ self-service vending pattern

**Repository Settings:**
- Name: `alz-workload-template`
- Visibility: `internal`
- Description: "Template repository for ALZ workload repositories with pre-configured Terraform workflows"
- Topics: `["azure", "terraform", "landing-zone", "template"]`

**Features:**
- Issues: ✅ Enabled
- Projects: ❌ Disabled
- Wiki: ❌ Disabled
- Discussions: ❌ Disabled

**Merge Settings:**
- Squash merge: ✅ Enabled (preferred)
- Merge commits: ❌ Disabled
- Rebase merge: ✅ Enabled
- Auto-delete branches: ✅ Enabled
- Squash commit format: PR title + commit messages

### Branch Protection (main branch)

**Modern Ruleset-Based Protection:**
- Require 1 approving review
- Dismiss stale reviews on new commits
- Required status checks:
  - `validate` - Terraform validation
  - `security` - Security scanning
  - `plan` - Terraform plan
- Strict status checks (must be up-to-date)
- Lifecycle protection (prevent accidental deletion)

**Legacy Protection (for push restrictions):**
- Push restrictions: `platform-engineering` team only

**Note:** Uses dual approach because GitHub's ruleset API doesn't fully support push restrictions yet.

### Team Access

- **platform-engineering:** `maintain` permission

---

## Validation Results

| Check | Status | Details |
|-------|--------|---------|
| Terraform Init | ✅ Pass | Provider v6.11.0 installed |
| Terraform Format | ✅ Pass | All files formatted correctly |
| Terraform Validate | ✅ Pass | Configuration is valid |
| Security Review | ✅ Pass | No hardcoded secrets |
| HashiCorp Standards | ✅ Pass | Module structure compliant |

---

## Current State vs Target State

### Before (Manual Configuration)
- ❌ Template flag not enabled via IaC
- ❌ Branch protection not managed by Terraform
- ❌ No audit trail for configuration changes
- ❌ Manual updates required via GitHub UI

### After (Terraform-Managed)
- ✅ Template flag managed via Terraform
- ✅ Complete branch protection via code
- ✅ Full audit trail through PR reviews
- ✅ Declarative, version-controlled configuration
- ✅ Repeatable and documentable changes

---

## Integration with ALZ Vending System

### Workflow Separation

**Parent Workflows (nathlan/.github-workflows):**
- Location: `.github/workflows/azure-terraform-deploy.yml`
- Type: Reusable workflow with `workflow_call` trigger
- Contains: Complete Terraform lifecycle
  - Validation (format, init, validate, TFLint)
  - Security scanning (Checkov)
  - Planning (with PR comments)
  - Deployment (with approval gates)

**Child Workflow (alz-workload-template):**
- Location: `.github/workflows/terraform-deploy.yml`
- Type: Caller workflow
- Contains: Minimal configuration that calls parent
- Passes: environment, terraform-version, working-directory, secrets

### Template Usage Pattern

When teams use the template:

1. **Create New Repo:** Click "Use this template" button
2. **Repo Created:** All files copied including child workflow
3. **Configure Secrets:** Add Azure OIDC credentials
4. **Push Changes:** Workflows execute automatically
5. **Deploy:** Calls parent reusable workflow

---

## Risk Assessment

**Risk Level:** 🟡 **MEDIUM**

### Why Medium?
- ✅ No destructive operations
- ✅ Template flag is non-disruptive
- ✅ Lifecycle protection prevents deletion
- ⚠️ Modifies existing repository configuration
- ⚠️ Changes branch protection rules
- ⚠️ Team references must be accurate

### Affected Resources
- Repository settings (template flag, features, merge settings)
- Branch protection rules (may require workflow adjustments)
- Team access permissions

---

## Next Steps for Platform Team

### 1. Review the Pull Request
Visit: https://github.com/nathlan/github-config/pull/11

Review:
- Terraform resource definitions
- Variable defaults and validation
- Security considerations
- Known limitations

### 2. Set GitHub Token

```bash
# Required scopes: repo, admin:org
export GITHUB_TOKEN="your_github_pat_here"
```

### 3. Run Terraform Plan

```bash
cd /path/to/github-config/terraform

terraform init
terraform plan -var="github_organization=nathlan"
```

### 4. Import Existing Resources

```bash
# Import repository
terraform import github_repository.alz_workload_template alz-workload-template

# Import team access
TEAM_ID=$(gh api orgs/nathlan/teams/platform-engineering --jq '.id')
terraform import 'github_team_repository.maintainers["platform-engineering"]' ${TEAM_ID}:alz-workload-template
```

### 5. Apply Configuration

```bash
terraform apply -var="github_organization=nathlan"
```

### 6. Verify Template Flag

1. Navigate to: https://github.com/nathlan/alz-workload-template
2. Verify "Use this template" button is visible (green button, top-right)
3. Check Settings > General to confirm "Template repository" is checked

---

## Known Limitations

### Conversation Resolution Requirement

**Issue:** GitHub provider doesn't support "Require conversation resolution before merging" via Terraform.

**Workaround:** Configure manually through GitHub UI:
1. Settings → General → Pull Requests
2. Enable "Require conversation resolution before merging"

**Tracking:** Documented in Terraform configuration, may be addressed in future provider versions.

---

## Agent Delegation Benefits

### Why This Pattern Works

**Orchestrator (ALZ Vending):**
- Coordinates end-to-end workflows
- Understands business context
- Delegates to specialists
- Doesn't write implementation code

**Specialist (GitHub Config):**
- Deep expertise in GitHub provider
- Generates proper IaC structure
- Validates and tests code
- Creates reviewed PRs

**Result:**
- ✅ Separation of concerns
- ✅ Expert-level implementation
- ✅ Auditability through PRs
- ✅ Maintainability via IaC

---

## Documentation Reference

### In github-config Repository

**README.md (235 lines):**
- Module overview and resources
- Prerequisites and setup
- Usage examples
- Import strategy
- Variable/output reference
- Security considerations
- State management
- Troubleshooting

**Handover Document (166 lines):**
- Context for CI/CD integration
- Template purpose and workflow
- Branch protection strategy
- Required status checks
- Import examples
- Risk assessment
- Dependencies

### In .github-private Repository

- **ALZ_MANUAL_CONFIGURATION_GUIDE.md** - Manual setup tasks
- **ALZ_SETUP_SUMMARY.md** - Implementation summary
- **This document** - Agent delegation pattern

---

## Success Criteria

The configuration is successful when:

- [x] PR created in github-config repository
- [x] Terraform code validated (init, fmt, validate)
- [x] Security review passed (no hardcoded secrets)
- [ ] PR reviewed and approved by platform team
- [ ] Terraform plan executed successfully
- [ ] Existing resources imported
- [ ] Configuration applied via Terraform
- [ ] Template flag verified in GitHub UI
- [ ] "Use this template" button functional

---

## Related PRs and Issues

- **This Implementation:** github-config PR #11
- **Infrastructure Setup:** .github-private (this repo)
- **Parent Workflows:** .github-workflows repository
- **Template Content:** alz-workload-template repository

---

## Conclusion

Successfully demonstrated the ALZ vending orchestrator pattern by delegating Terraform IaC generation to the github-config specialist agent. The configuration will enable proper template repository functionality while maintaining all settings through version-controlled, auditable infrastructure-as-code.

The separation of reusable workflows (in `.github-workflows`) and child workflows (in template) provides a clean architecture for the ALZ self-service vending system.

---

**Status:** ✅ Agent delegation complete | ⏳ Awaiting platform team review and apply  
**Next Action:** Platform team reviews PR #11 and applies Terraform configuration
