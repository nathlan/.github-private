# Example Terraform Patterns for GitHub Configuration

This directory contains reusable patterns for common GitHub configuration scenarios.

## Available Patterns

1. **Branch Protection** - Apply consistent branch protection rules
2. **Team Access** - Manage team-based repository access
3. **Repository Templates** - Create repositories with standard settings
4. **Organization Settings** - Standardize organization-wide configuration

## Usage

Copy the relevant pattern into your `main.tf` and customize as needed. Each pattern includes:
- Data source queries for existing resources
- Resource definitions for desired state
- Comments explaining configuration options

## Customization Tips

- Replace hardcoded lists with variables for flexibility
- Adjust protection rules to match your workflow
- Add validation rules to variables
- Use locals for complex transformations

## Contributing New Patterns

When adding new patterns, include:
- Clear comments explaining purpose
- Example values for all configuration options
- References to Terraform provider documentation
