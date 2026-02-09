# CI/CD Workflow Templates

This directory contains reusable templates for the CI/CD Workflow Agent.

## Templates

- **Workflow Files**: Complete GitHub Actions workflows ready to customize
  - `github-provider.yml` - GitHub provider Terraform workflow
  - `azure-provider.yml` - Azure provider Terraform workflow

- **Documentation**: Standard documentation templates
  - `DEPLOYMENT.md` - Deployment process guide
  - `ROLLBACK.md` - Rollback procedures
  - `TROUBLESHOOTING.md` - Common issues and solutions

- **PR Template**: Pull request description template
  - `pr-description.md` - Comprehensive PR template

## Usage

The CI/CD Workflow Agent automatically reads these templates and customizes them based on:
- Detected provider (github/azurerm)
- Repository context
- User requirements
