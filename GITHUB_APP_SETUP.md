# GitHub App Authentication Setup

## Current Status
The GitHub App credentials (`TF_MODULE_APP_ID` and `TF_MODULE_APP_PRIVATE_KEY`) are configured in the repository but are not currently accessible to the Copilot agent workflow.

## Why This Is Needed
The agent needs these credentials to:
1. Authenticate with the GitHub API using the organization's GitHub App
2. Push changes to the `terraform-azurerm-resourcegroup` repository
3. Create pull requests automatically

## How to Make Credentials Available

### Option 1: Pass Secrets to Dynamic Workflow (Recommended)
The Copilot dynamic workflow needs to be configured to pass these secrets to the agent. This would typically be done in the workflow configuration or through GitHub's Copilot configuration.

**Note**: This may require GitHub support or configuration changes at the organization level, as dynamic Copilot workflows have specific security boundaries.

### Option 2: Manual Deployment (Current Workaround)
Since the credentials aren't currently accessible to the agent, use the deployment script manually:

```bash
# Set the environment variables (get values from GitHub Secrets)
export TF_MODULE_APP_ID="your_app_id"
export TF_MODULE_APP_PRIVATE_KEY="your_private_key"

# Run the deployment script
/tmp/deploy-with-github-app.sh
```

### Option 3: Use gh CLI Directly
If you have gh CLI authenticated:

```bash
cd /tmp/terraform-azurerm-resourcegroup
git push -u origin feature/update-location-variable-and-docs
gh pr create --title "feat: add location variable with validation and regenerate docs" \
  --body "See commit for details"
```

## Agent Instructions Update
The agent instructions already mention the GitHub App authentication:

```
**GitHub App Authentication (WORKING ✅):**
- Uses organization-level GitHub App with repo permissions
- App ID: TF_MODULE_APP_ID (variable)
- Private Key: TF_MODULE_APP_PRIVATE_KEY (secret)
- **Works with**: Public repositories in the organization
- **Capabilities**: Create repos, branches, push files, create PRs
```

However, for this to actually work in the agent's execution context, the secrets need to be:
1. Available in the workflow's environment
2. Passed to the agent's execution container
3. Accessible via environment variables during agent execution

## Scripts Created
Two helper scripts have been created:

1. **/tmp/github-app-auth.sh** - Generates GitHub App JWT and gets installation access token
2. **/tmp/deploy-with-github-app.sh** - Complete deployment script that:
   - Authenticates using GitHub App (if credentials available)
   - Falls back to checking gh CLI authentication
   - Pushes changes to remote repository
   - Creates pull request

## Testing the Setup
To test if the credentials are available:

```bash
if [ -n "$TF_MODULE_APP_ID" ] && [ -n "$TF_MODULE_APP_PRIVATE_KEY" ]; then
  echo "✅ Credentials are available"
  /tmp/github-app-auth.sh
else
  echo "❌ Credentials are NOT available"
  echo "TF_MODULE_APP_ID: ${TF_MODULE_APP_ID:-not set}"
  echo "TF_MODULE_APP_PRIVATE_KEY: ${TF_MODULE_APP_PRIVATE_KEY:+set}"
fi
```

## Current State
- ✅ terraform-azurerm-resourcegroup repository is public
- ✅ GitHub App is configured in the organization
- ✅ Secrets TF_MODULE_APP_ID and TF_MODULE_APP_PRIVATE_KEY exist
- ❌ Secrets are not accessible in the Copilot agent's execution environment
- ✅ Workaround scripts are available for manual deployment

## Next Steps
1. Investigate how to pass secrets to Copilot dynamic workflows
2. Or use manual deployment with the provided scripts
3. Once PR is created, link it in the .github-private PR
