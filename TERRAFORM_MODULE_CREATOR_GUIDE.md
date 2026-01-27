# Terraform Module Creator - Usage Guide

This guide explains how to use the Terraform Module Creator agent and the associated setup steps file.

## Overview

The Terraform Module Creator agent is designed to help you create and manage private Terraform modules that consume Azure Verified Modules (AVM). It automates validation, testing, and PR generation while ensuring best practices and security standards are met.

## Files Included

### 1. `copilot-setup-steps.yml`
This file contains the environment setup steps using GitHub Marketplace Actions:
- **Terraform** - hashicorp/setup-terraform@v3 (official HashiCorp action)
- **TFlint** - terraform-linters/setup-tflint@v4 (official TFLint action)
- **Checkov** - pip3 installation (bridgecrewio/checkov-action is for scanning workflows)
- **Terraform environment** - Configured for CI/CD automation

**Benefits of using Marketplace Actions:**
- Maintained by official teams
- Reliable and tested installations
- Automatic updates and security patches
- Cross-platform compatibility

### 2. `agents/terraform-module-creator.agent.md`
The custom Copilot agent that:
- Creates Terraform modules following best practices
- Consumes Azure Verified Modules (AVM)
- Validates using fmt, validate, TFlint, and Checkov
- Generates PRs with comprehensive descriptions
- Handles versioning and releases
- Manages hook failures gracefully

## Setup Instructions

### Prerequisites
1. A GitHub repository for your Terraform modules
2. Access to GitHub Copilot with custom agents enabled
3. This `.github-private` repository in your organization

### Installation
The `copilot-setup-steps.yml` file will be automatically processed by GitHub Copilot to set up the environment. No manual installation is required.

## Using the Terraform Module Creator Agent

### Basic Usage

1. **Invoke the agent** in GitHub Copilot Chat:
   ```
   @terraform-module-creator create a module for Azure Virtual Network
   ```

2. **Specify requirements**:
   ```
   @terraform-module-creator create a module that:
   - Uses AVM for Virtual Network
   - Includes subnet configuration
   - Supports network security groups
   - Has examples for basic and advanced usage
   ```

3. **The agent will**:
   - Design the module structure
   - Create all required files (main.tf, variables.tf, outputs.tf, etc.)
   - Integrate Azure Verified Modules
   - Run validation tools
   - Fix any issues found
   - Report validation status

### Creating a New Module

Example conversation with the agent:

```
User: Create a new Terraform module for Azure Storage Account that uses AVM

Agent: I'll create a storage account module using Azure Verified Modules. 
       Let me design the structure...

[Agent creates module files]

Agent: Module created with the following structure:
       - main.tf (using AVM storage account module)
       - variables.tf (10 input variables)
       - outputs.tf (8 outputs)
       - versions.tf (Terraform >= 1.0, AzureRM >= 3.0)
       - README.md (comprehensive documentation)
       - examples/basic/ (working example)
       
       Running validation...
       ✅ terraform fmt: PASS
       ✅ terraform validate: PASS
       ✅ tflint: PASS
       ✅ checkov: PASS (no critical issues)
       
       Module is ready for use!
```

### Validation Workflow

The agent automatically runs these validations in order:

1. **Terraform fmt** - Ensures consistent formatting
2. **Terraform validate** - Checks syntax and configuration
3. **TFlint** - Validates best practices and catches potential issues
4. **Checkov** - Scans for security vulnerabilities and compliance issues

If any validation fails, the agent will:
- Identify the specific issue
- Attempt to auto-fix when safe
- Report issues that require manual review
- Provide clear remediation steps

### Creating Pull Requests

When working on module updates:

```
User: Update the module to add lifecycle rules and create a PR

Agent: I'll add lifecycle rules to the storage account module...

[Agent makes changes and validates]

Agent: Changes validated successfully. Creating PR...
       
       PR created: #123 "feat: add lifecycle management to storage module"
       Title: feat: add lifecycle management to storage module
       Description:
       - Added lifecycle_rule variable
       - Integrated with AVM lifecycle block
       - Updated examples with lifecycle configuration
       - All validations passed
       
       Ready for review!
```

### Versioning and Releases

The agent follows semantic versioning (SemVer):

```
User: Release version 1.2.0 with the new lifecycle features

Agent: Creating release v1.2.0...
       
       Version type: MINOR (new features, backward-compatible)
       
       Created:
       - Git tag: v1.2.0
       - GitHub release with changelog
       - Updated documentation
       
       Release published: https://github.com/org/repo/releases/tag/v1.2.0
```

## Module Standards

### Required Files
Every module created by the agent includes:
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variables with descriptions
- `outputs.tf` - Outputs with descriptions
- `versions.tf` - Version constraints
- `README.md` - Documentation with usage examples
- `examples/basic/` - At least one working example
- `.tflint.hcl` - TFLint configuration

### Naming Conventions
- Modules: `terraform-azurerm-<service>-<purpose>`
- Variables: `snake_case`
- Resources: Descriptive names
- Outputs: `snake_case`

### Azure Verified Modules (AVM)
The agent uses AVM modules from:
- Registry: `registry.terraform.io/Azure/avm-*`
- Version pinning: `version = "~> 1.0"`
- Documentation: Links to AVM module docs in README

## Validation Tools

### TFlint Configuration
Default configuration includes:
- Azure provider plugin
- Best practice rules
- Naming convention validation
- Required variable checks

### Checkov Security Scanning
Scans for:
- Security misconfigurations
- Compliance violations
- Best practice deviations
- Potential vulnerabilities

Security issues are categorized:
- **CRITICAL/HIGH** - Must be fixed
- **MEDIUM** - Should be reviewed
- **LOW** - Optional improvements

## Handling Failures

### Hook Failures
If pre-commit or CI hooks fail:

1. Agent identifies the failure type
2. Attempts auto-fix for:
   - Formatting issues (terraform fmt)
   - Safe linting fixes
3. Reports unresolvable issues with:
   - Clear error message
   - Root cause analysis
   - Remediation steps

### Validation Failures
If validation fails:

```
Agent: Validation failed at checkov step:
       
       ❌ HIGH: Storage account allows public blob access
       File: main.tf:15
       Recommendation: Set allow_blob_public_access = false
       
       Applying fix...
       ✅ Fixed: Updated allow_blob_public_access
       
       Re-running validation...
       ✅ All checks passed
```

## Best Practices

### Working with the Agent
1. **Be specific** - Provide clear requirements for modules
2. **Review outputs** - Check generated code before committing
3. **Trust validations** - The agent enforces security and best practices
4. **Iterate** - Refine modules through conversation
5. **Document** - Agent creates comprehensive docs, but add context as needed

### Module Development
1. Start with basic functionality
2. Add features incrementally
3. Validate at each step
4. Use examples to test
5. Version appropriately

### Security
1. Never bypass security validations
2. Review Checkov findings
3. Document security exceptions with justification
4. Use secure defaults
5. Follow Azure security best practices

## Troubleshooting

### Agent Not Responding
- Ensure the `.github-private` repository is accessible
- Verify the agent file is in the `agents/` directory
- Check agent name in your invocation

### Setup Steps Not Running
- Verify `copilot-setup-steps.yml` is in the repository root
- Check YAML syntax is valid
- Ensure all required commands are available

### Validation Failures
- Review error messages carefully
- Run validations locally to debug
- Check TFLint and Checkov configurations
- Ensure Terraform version compatibility

### Module Issues
- Verify AVM module versions are available
- Check provider version constraints
- Ensure required variables are defined
- Test examples locally

## Examples

### Example 1: Simple Storage Account Module
```
@terraform-module-creator create a basic storage account module using AVM
```

### Example 2: Complex Networking Module
```
@terraform-module-creator create a module for:
- Virtual Network with AVM
- 3 subnets (web, app, data)
- Network Security Groups
- Route tables
- Peering configuration
```

### Example 3: Update Existing Module
```
@terraform-module-creator add support for private endpoints to the storage module
```

### Example 4: Create Release
```
@terraform-module-creator create version 2.0.0 with breaking changes for new tagging strategy
```

## Support and Resources

### Terraform Resources
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://aka.ms/avm)

### Validation Tools
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Checkov Documentation](https://www.checkov.io/)

### Best Practices
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Terraform Best Practices](https://learn.microsoft.com/azure/developer/terraform/best-practices)

## Contributing

To improve the agent or setup steps:
1. Update the agent instructions in `terraform-module-creator.agent.md`
2. Modify setup steps in `copilot-setup-steps.yml`
3. Test changes thoroughly
4. Create PR with clear description
5. Request review from team

## License

This agent and setup configuration are provided as-is for internal use within your organization.
