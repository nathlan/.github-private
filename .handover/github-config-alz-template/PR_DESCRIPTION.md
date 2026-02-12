## Configure alz-workload-template Repository via Terraform

### Summary

This PR adds Terraform configuration to manage the existing `alz-workload-template` repository, specifically setting `is_template = true` to enable GitHub template functionality via Infrastructure-as-Code.

**Key Discovery:** The GitHub Terraform provider (v6.0+) DOES support the `is_template` attribute. Previous documentation incorrectly stated this could only be set manually via the GitHub UI.

### Changes

- **Add** `github_repository.alz_workload_template` resource to manage the template repository
- **Set** `is_template = true` to enable template functionality
- **Configure** repository settings aligned with ALZ standards  
- **Add** lifecycle protection (`prevent_destroy = true`) to prevent accidental deletion
- **Update** outputs.tf to export template repository details
- **Add** IMPORT_INSTRUCTIONS.md with detailed import and verification steps

### Critical Configuration

The key addition to `main.tf`:

```hcl
resource "github_repository" "alz_workload_template" {
  name        = "alz-workload-template"
  is_template = true  # Enable template functionality
  
  # ... additional ALZ-aligned settings
  
  lifecycle {
    prevent_destroy = true  # Safety protection
  }
}
```

### Before Applying

⚠️ **Import Required:** The repository already exists and must be imported into Terraform state before applying:

```bash
cd terraform/
terraform import github_repository.alz_workload_template alz-workload-template
```

See `terraform/IMPORT_INSTRUCTIONS.md` for detailed steps.

### Expected Changes

After import, `terraform plan` should show:
- **is_template:** `false → true` ⭐ (the critical change)

### Verification

After applying:
1. Visit: https://github.com/nathlan/alz-workload-template
2. Confirm "Use this template" button appears

### Risk Assessment

🟢 **Low Risk** - Only manages existing repository settings, no destructive operations

### Files Changed

- `terraform/main.tf` (+47 lines)
- `terraform/outputs.tf` (+25 lines)  
- `terraform/IMPORT_INSTRUCTIONS.md` (new file)
