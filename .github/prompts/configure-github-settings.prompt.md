---
name: Configure GitHub Settings
description: Gather requirements and hand off to GitHub Configuration Agent to generate Terraform IaC
target-agent: github-config
---

# Configure GitHub Settings via Infrastructure-as-Code

I'll help you manage GitHub configuration using Terraform. Let me understand what you need to configure:

## Scope

What level are we working at?
- **Repository**: Specific repos or pattern-matched repos (`api-*`, all private repos, etc.)
- **Organization**: Org-wide settings, teams, or multiple repositories
- **Enterprise**: Enterprise-level policies and settings

## What to Configure

Common configurations:
- **Branch Protection**: Require reviews, status checks, signed commits
- **Team Access**: Grant teams access to repositories with specific permissions
- **Repository Settings**: Features (issues, wiki), merge strategies, security
- **Organization Settings**: Member privileges, repository defaults, security policies
- **Actions/Security**: Workflow permissions, secrets, Dependabot
- **Webhooks**: Repository or organization webhooks
- **Other**: Describe your specific need

## Details Needed

Please provide:
1. **Target resources**: Which repos/teams/resources? (names, patterns, or "all")
2. **Specific settings**: What exact configuration do you want?
3. **Requirements**: Any special cases or exceptions?

## Example Requests

- "Enable branch protection requiring 2 reviews on all repos starting with 'api-'"
- "Grant the backend-team push access to database-service and auth-service repos"
- "Set organization defaults: disable public repos, require 2FA, enable Dependabot"
- "Create deployment environments with approval gates for production repos"

---

**Once you provide the details, I'll hand this off to the GitHub Configuration Agent to:**
1. Discover current GitHub state
2. Generate Terraform configuration
3. Create a pull request with the changes
4. Provide you with review instructions

All changes require human review and approval before being applied - nothing will be modified automatically.
