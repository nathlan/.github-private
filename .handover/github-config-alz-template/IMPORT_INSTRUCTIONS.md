# Import Instructions for alz-workload-template

## Overview

This Terraform configuration adds management of the existing `alz-workload-template` repository, specifically to set `is_template = true` to enable it as a GitHub template repository.

## Initial Import Required

Since the repository already exists, it must be imported into Terraform state before applying:

```bash
cd terraform/
terraform import github_repository.alz_workload_template alz-workload-template
```

## Expected Changes on First Apply

After import, running `terraform plan` should show these changes:

1. **is_template:** `false → true` (the critical change)
2. **Possibly other minor settings** depending on current repository configuration

## Verify Import

After import, verify the repository is in state:

```bash
terraform state show github_repository.alz_workload_template
```

## Apply Changes

Once imported, apply the configuration:

```bash
terraform apply
```

This will set `is_template = true` on the repository, enabling the "Use this template" functionality.

## Verification

After applying, verify in GitHub:
- Visit: https://github.com/nathlan/alz-workload-template
- Confirm "Use this template" button appears (green button near top-right)

## Integration with Existing Configuration

The `alz-workload-template` resource is added alongside the existing `repos` for_each loop configuration. They are independent and will not conflict.
