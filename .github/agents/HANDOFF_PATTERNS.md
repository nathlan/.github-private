# GitHub Configuration Handoff Patterns

This directory contains tools for transitioning to the GitHub Configuration Agent to implement infrastructure-as-code for GitHub settings.

## Available Options

### Option 1: Direct Handoff Prompt
**File:** `.github/prompts/configure-github-settings.prompt.md`

**When to use:** You know exactly what you want to configure

**Usage:** Use this prompt to structure your request, then mention the GitHub Configuration Agent directly

**Example:**
```
@github-config I want to enable branch protection requiring 2 reviews on all repos starting with 'api-'
```

### Option 2: Settings Planner Agent
**File:** `agents/github-settings-planner.agent.md`

**When to use:** You want help discovering current state and planning changes

**Usage:** Start a conversation with the planner agent, which will:
1. Ask clarifying questions
2. Discover current GitHub state
3. Show you what will be affected
4. Hand off to github-config when ready

**Example:**
```
@github-settings-planner I want to standardize branch protection across my repositories
```

The planner will guide you through options and then hand off to github-config.

### Option 3: From Another Agent
**Implementation:** Use the `inbound-prompts` pattern defined in `github-config.agent.md`

**When to use:** You're building an agent that needs to delegate GitHub configuration

**Example handoff:**
```yaml
handoffs:
  - label: "Configure GitHub Settings"
    agent: github-config
    prompt: |
      Generate Terraform for the following GitHub configuration:

      Scope: Organization
      Resources: All repositories matching 'api-*'
      Configuration: Branch protection with 2 required reviews
      Risk: Medium (modifies security settings)
    send: false
```

## Handoff Flow

```
┌─────────────────────────┐
│   User Request          │
│  "Configure GitHub..."  │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────────┐
    │  Direct Request?  │
    └───────┬───────────┘
            │
       ┌────┴────┐
       │         │
    Yes│         │No
       │         │
       ▼         ▼
┌──────────┐  ┌─────────────────────┐
│ github-  │  │ github-settings-    │
│ config   │  │ planner             │
└────┬─────┘  └──────┬──────────────┘
     │               │
     │               │ (Discovers state,
     │               │  clarifies needs)
     │               │
     │               ▼
     │        ┌──────────────┐
     │        │ User confirms│
     │        └─────┬────────┘
     │              │
     │              │ Handoff with
     │              │ requirements
     │              │
     │              ▼
     │        ┌──────────┐
     └────────► github-  │
              │ config   │
              └────┬─────┘
                   │
                   │ (Generates Terraform,
                   │  creates PR)
                   │
                   ▼
            ┌────────────────┐
            │  Pull Request  │
            │  (Human Review)│
            └────────────────┘
```

## When to Use Each

### Use Direct Handoff When:
- ✅ You know exact repositories/resources
- ✅ You know specific settings needed
- ✅ You're familiar with GitHub configuration options
- ✅ You want fastest path to implementation

### Use Settings Planner When:
- ✅ You need help discovering current state
- ✅ You're not sure what's possible
- ✅ You want to see impact before committing
- ✅ You need to explore options
- ✅ You're planning complex org-wide changes

## Example Requests

### Direct to github-config:
```
@github-config Enable branch protection on repos: api-gateway, api-auth, api-users
Require 2 reviews, dismiss stale reviews, require status checks
```

### Via github-settings-planner:
```
@github-settings-planner I want to standardize security settings across all production repositories
```

The planner will:
1. Ask what you mean by "production repositories"
2. Show current security settings
3. Propose standardization options
4. Hand off to github-config when you confirm

## Benefits of Handoff Pattern

- **Safety:** Requirements gathering before implementation
- **Clarity:** Explicit summary of changes before PR creation
- **Flexibility:** Choose level of guidance you need
- **Auditability:** Clear handoff points with confirmed requirements
- **Separation of Concerns:** Planning vs. implementation

## Tips

1. **Be Specific in Handoffs:** Include scope, resources, and configuration details
2. **Include Risk Assessment:** Help github-config prioritize validation
3. **Confirm Before Handoff:** Always show user what will happen
4. **Use send: false:** Let users review handoff prompt before sending

---

All implementations ultimately create Terraform PRs that require human review - nothing is applied automatically.
