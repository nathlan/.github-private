# terraform-azurerm-resourcegroup Module Updates

## Summary
Updated the terraform-azurerm-resourcegroup module to add a location variable with default value and validation, and regenerated all documentation using terraform-docs.

## Changes Made

### 1. Added Location Variable (`variables.tf`)
Added new `location` variable after the `name` variable:
```hcl
variable "location" {
  type        = string
  description = "Optional. The Azure location where the resource group should be created. Restricted to Australia East or Australia Southeast."
  default     = "australiaeast"

  validation {
    condition     = contains(["australiaeast", "australiasoutheast"], lower(var.location))
    error_message = "Location must be either 'australiaeast' or 'australiasoutheast'."
  }
}
```

### 2. Updated main.tf
Changed from hardcoded location to using the variable:
```hcl
# Before:
location = "australiaeast"

# After:
location = var.location
```

### 3. Created .terraform-docs.yml Configuration Files
- Root: `.terraform-docs.yml` - Configures documentation generation for the module
- Example: `examples/basic/.terraform-docs.yml` - Configures documentation for the example

### 4. Regenerated Documentation
- `README.md` - Fully regenerated with terraform-docs, includes new location variable
- `examples/basic/README.md` - Regenerated with terraform-docs markers

## Files Changed
1. `.terraform-docs.yml` - NEW
2. `main.tf` - UPDATED (uses var.location)
3. `variables.tf` - UPDATED (added location variable)
4. `README.md` - UPDATED (regenerated with terraform-docs)
5. `examples/basic/.terraform-docs.yml` - NEW
6. `examples/basic/README.md` - UPDATED (regenerated with terraform-docs)

## Validation Status
- ✅ terraform fmt -recursive
- ✅ terraform init
- ✅ terraform validate
- ✅ terraform-docs generated successfully
- ⚠️  tflint (GitHub API rate limit - skipped)
- ⚠️  checkov (not installed - skipped)

## Branch Information
- Branch name: `feature/update-location-variable-and-docs`
- Base branch: `main`
- Commit message: "feat: add location variable with validation and regenerate docs"

## Next Steps Required
Since automated GitHub API authentication is not available, manual steps are needed:

### Option 1: Using gh CLI (Recommended)
```bash
cd /tmp/terraform-azurerm-resourcegroup
gh auth login
git push -u origin feature/update-location-variable-and-docs
gh pr create --draft --title "feat: add location variable with validation and regenerate docs" --body "See commit message for details"
gh pr ready
```

### Option 2: Manual Push and PR Creation
1. Navigate to module directory: `cd /tmp/terraform-azurerm-resourcegroup`
2. Push branch: `git push -u origin feature/update-location-variable-and-docs`
3. Create PR via GitHub web interface
4. Use PR title: "feat: add location variable with validation and regenerate docs"
5. Include changes summary in PR description

## PR Description Template
```
# Add Location Variable with Validation and Regenerate Documentation

## Changes
- ✅ Added `location` variable with default value `australiaeast`
- ✅ Added validation to restrict location to `australiaeast` or `australiasoutheast`
- ✅ Updated `main.tf` to use the location variable instead of hardcoded value
- ✅ Created `.terraform-docs.yml` configuration files
- ✅ Regenerated all documentation using terraform-docs
- ✅ Validated with terraform fmt and terraform validate

## Breaking Changes
None - the default behavior remains the same (australiaeast)

## Migration Notes
Existing users can continue without changes. To use australiasoutheast, explicitly set the location variable:
```hcl
module "resource_group" {
  source   = "github.com/nathlan/terraform-azurerm-resourcegroup"
  name     = "rg-example"
  location = "australiasoutheast"
}
```
