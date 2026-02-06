# Validation Enforcement Configuration

This document explains how validation steps are enforced in the Terraform module creation workflow for this organization.

## Quick Answer

**How are validation checks enforced?**

Using a **hybrid approach**:

| Validation Check | Enforcement Method | Why |
|-----------------|-------------------|-----|
| **Trailing whitespace, line endings, YAML syntax** | ✅ **Pre-commit hooks** | Fast (<1s), no dependencies |
| **Block .tf files in .github-private** | ✅ **`.gitignore` + Pre-commit** | Multi-layer protection |
| **Block LICENSE/README changes** | ✅ **Pre-commit hooks** | Critical safety check |
| **terraform fmt, validate** | ❌ **Manual** | Requires Terraform + module context |
| **TFLint** | ❌ **Manual** | Requires plugin downloads (100MB+), slow |
| **Checkov security scan** | ❌ **Manual** | Complex (30-120s), requires analysis |
| **terraform-docs** | ❌ **Manual** | Requires module context |

**TL;DR**: Fast/simple checks use pre-commit hooks. Complex checks (Terraform validation, security scanning) are manual because they're slow, context-dependent, and require external dependencies.

---

## Overview

The validation enforcement follows a **hybrid approach** that balances automation, complexity, and developer experience:

- **Pre-commit hooks**: Used for lightweight, fast checks that prevent common mistakes
- **Manual validation**: Used for complex security/linting checks that require module dependencies and take longer to run

## Current Configuration

### Multi-Layer Protection Strategy

This repository uses **defense in depth** for critical protections:

1. **`.gitignore`** (First Layer - Git Level)
   - Blocks `.tf` files from being staged
   - Blocks archives (`.tar.gz`, `.zip`) from being staged
   - Prevents accidental `git add` of Terraform code
   - Works even if pre-commit is not installed

2. **Pre-commit Hooks** (Second Layer - Commit Level)
   - Provides backup enforcement if `.gitignore` is bypassed (`git add -f`)
   - Blocks LICENSE and README modifications (not in `.gitignore`)
   - Enforces code quality checks (whitespace, line endings, YAML)
   - Requires `pre-commit install` to activate

This layered approach ensures maximum protection against accidental commits of module code to the control repository.

### Pre-Commit Hooks (`.pre-commit-config.yaml`)

**Status**: ✅ Installed and Active

Pre-commit hooks are installed and configured to run automatically on every commit attempt. These are **enforced locally** before code reaches the repository.

#### What's Enforced via Pre-Commit

1. **Standard Code Quality Checks**
   - `trailing-whitespace` - Removes trailing whitespace
   - `end-of-file-fixer` - Ensures files end with a newline
   - `check-yaml` - Validates YAML syntax
   - `check-added-large-files` - Prevents files >1MB (configurable)
   - `check-merge-conflict` - Detects merge conflict markers
   - `mixed-line-ending` - Ensures consistent line endings

2. **Repository Protection Rules** (Custom Local Hooks)
   - `no-terraform-files` - **Blocks `.tf` files** from being committed (backup to `.gitignore`)
   - `no-binaries` - **Blocks binary/archive files** (backup to `.gitignore` for archives)
   - `protect-license` - **Blocks modifications** to LICENSE file
   - `protect-readme` - **Blocks modifications** to README.md file

   **Note**: `.gitignore` provides primary protection for `.tf` files and archives - they can't even be staged. Pre-commit hooks provide a secondary enforcement layer.

**Why These Use Pre-Commit:**
- Fast execution (< 1 second total)
- No external dependencies required
- Catch mistakes immediately before commit
- Prevent accidental commits of module code to control repository

**Installation:**
```bash
# In any module or repository with .pre-commit-config.yaml
pre-commit install
pre-commit install-hooks

# Test manually
pre-commit run --all-files
```

### Manual Validation Checks

The following checks are **NOT** in pre-commit hooks and must be run manually during module development:

#### 1. **Terraform Formatting & Validation**

**Commands:**
```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

**Why Manual:**
- Requires Terraform installation and provider downloads
- Needs to run in module context (not in `.github-private`)
- Module-specific validation (depends on which module you're working on)

**When to Run:**
- Before creating PR
- After making code changes
- As part of module validation workflow

#### 2. **TFLint** (`.tflint.hcl.template`)

**Command:**
```bash
tflint --init && tflint --recursive
```

**Configuration:**
- Terraform recommended preset enabled
- Azure-specific rules via `azurerm` plugin
- Naming convention enforcement (snake_case)
- Documentation requirements (outputs, variables)

**Why Manual:**
- Requires downloading Azure plugin (~100MB)
- Needs Terraform module context
- Takes 5-30 seconds depending on module size
- Different plugins needed for different cloud providers

**When to Run:**
- Before creating PR
- After structural changes
- When adding new resources/variables

#### 3. **Checkov Security Scanning** (`.checkov.yml.template`)

**Commands:**
```bash
# Using experimental Terraform-managed modules approach
export CHECKOV_EXPERIMENTAL_TERRAFORM_MANAGED_MODULES=True
terraform init -backend=false
checkov -d . --framework terraform --skip-path .terraform --download-external-modules false --compact --quiet
```

**Configuration:**
- Framework: Terraform
- Skip checks: `CKV_TF_1` (module source commit hash - acceptable for registry modules)
- Uses experimental flag to scan Terraform-downloaded modules

**Why Manual (NOT in Pre-Commit):**
- **Complexity**: Requires downloading external AVM modules via `terraform init`
- **Performance**: Can take 30-120 seconds for full scan including external modules
- **Context-Dependent**: Results vary based on module structure and dependencies
- **Network Dependencies**: Needs to download modules (mitigated by experimental flag, but still requires initial `terraform init`)
- **Security Traceability Required**: Each failure needs manual analysis to determine if exposed, documented, or fixed in wrapper
- **Multi-Layer Validation**: Requires depth-first scanning for modules with submodules

**Validation Workflow:**
1. Initialize Terraform to download external modules
2. Scan external AVM module in `.terraform/modules/`
3. Create traceability matrix for findings
4. Scan wrapper module
5. Verify all exposed parameters have secure defaults
6. Document results in PR

**When to Run:**
- Before creating PR (mandatory)
- After changing security-related parameters
- When updating AVM module versions

#### 4. **terraform-docs** (`.terraform-docs.yml`)

**Commands:**
```bash
# Root module
terraform-docs markdown table --config .terraform-docs.yml .

# Submodules (if present)
terraform-docs markdown table --output-file README.md --output-mode inject modules/blob

# Examples
terraform-docs markdown table --output-file README.md --output-mode inject examples/basic
```

**Configuration:**
- Format: Markdown table
- Output: Inject into README.md between markers
- Settings: Anchor, show defaults, required flags

**Why Manual (NOT in Pre-Commit):**
- Requires Terraform module context
- Needs to parse `.tf` files to extract documentation
- Module-specific (root vs submodules vs examples)
- Can be added to pre-commit in individual module repos (optional)

**When to Run:**
- After changing variables, outputs, or resources
- Before creating PR
- As final step before validation

## Summary: Pre-Commit vs Manual

| Check | Enforcement | Why |
|-------|-------------|-----|
| **Trailing whitespace** | Pre-commit | Fast, no dependencies |
| **YAML validation** | Pre-commit | Fast, no dependencies |
| **Large files** | Pre-commit | Fast, prevents repo bloat |
| **Block .tf files in .github-private** | Pre-commit | Fast, critical safety check |
| **Block binaries** | Pre-commit | Fast, prevents accidents |
| **Protect LICENSE/README** | Pre-commit | Fast, critical safety check |
| **terraform fmt** | Manual | Requires Terraform + module context |
| **terraform validate** | Manual | Requires Terraform + module context |
| **TFLint** | Manual | Requires plugin downloads, module context |
| **Checkov** | Manual | Complex, slow, requires analysis |
| **terraform-docs** | Manual | Requires module context |

## Rationale for Hybrid Approach

### Why NOT Add Terraform Validation to Pre-Commit?

**Considered but rejected for these reasons:**

1. **Performance**: Terraform validation can take 10-60 seconds per commit
   - Slows down developer workflow
   - Frustrating for quick fixes or documentation changes

2. **Context Dependency**:
   - Pre-commit runs in `.github-private` repo
   - Module code is in `/tmp/` or separate repositories
   - Hook would need complex path detection

3. **Developer Experience**:
   - Not all commits in `.github-private` involve Terraform
   - Many changes are to tracking docs, agent configs, templates
   - Would add unnecessary overhead

4. **Complexity**:
   - Requires Terraform installation check
   - Needs to detect module directories
   - Would need skip conditions for non-module commits

### Why NOT Add Checkov to Pre-Commit?

**Strongly considered but decided against:**

1. **Time**: 30-120 seconds per scan is too slow for commit hooks
2. **Complexity**: Requires `terraform init` to download modules first
3. **Analysis Required**: Each failure needs human judgment on exposure/fixes
4. **Network Dependency**: Even with experimental flag, requires initial module download
5. **False Positives**: External module examples often fail (intentional)
6. **Traceability**: Must document each finding in PR - can't be automated

### What Could Be Added to Pre-Commit (Future Consideration)?

**Individual Module Repositories** could add to their own `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.19.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "."]

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: "v1.96.0"
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

**Why this works for module repos but not `.github-private`:**
- Module repos only contain one module (clear context)
- Every commit is Terraform-related
- Developers expect validation on every commit
- `.github-private` is a control/template repo, not a module

## Verification

### Test Pre-Commit Hooks

```bash
# Test all hooks without committing
pre-commit run --all-files

# Test specific hook
pre-commit run no-terraform-files --all-files

# Try to add a .tf file (blocked by .gitignore first)
touch test.tf
git add test.tf  # Will fail: "The following paths are ignored by one of your .gitignore files"

# Force add to test pre-commit hook (not recommended in practice)
git add -f test.tf
git commit -m "test"  # Will be blocked by pre-commit hook

# Cleanup
git restore --staged test.tf 2>/dev/null
rm test.tf
```

### Verify Configuration Files Exist

```bash
# In .github-private repo
ls -la .pre-commit-config.yaml      # ✓ Present
ls -la .gitignore                    # ✓ Present (blocks .tf, archives at git level)
ls -la .tflint.hcl.template         # ✓ Present (template for modules)
ls -la .checkov.yml.template        # ✓ Present (template for modules)
ls -la .terraform-docs.yml          # ✓ Present (template for modules)
```

### Check Pre-Commit Installation

```bash
pre-commit --version                # Should show version (e.g., 4.5.1)
ls -la .git/hooks/pre-commit       # Should exist and be executable
```

## Workflow Integration

### For `.github-private` Repository (This Repo)

1. **Pre-commit runs automatically** on every commit attempt
2. Blocks invalid changes (binaries, .tf files, LICENSE/README modifications)
3. Fixes whitespace/formatting issues automatically
4. **No Terraform validation** (not applicable to this repo)

### For Terraform Module Repositories

1. **Manual validation** before PR:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   tflint --init && tflint --recursive
   export CHECKOV_EXPERIMENTAL_TERRAFORM_MANAGED_MODULES=True
   checkov -d . --framework terraform --skip-path .terraform --download-external-modules false
   terraform-docs markdown table --config .terraform-docs.yml .
   ```

2. **Optionally add pre-commit** to module repo for auto-formatting

3. **CI/CD validation** (future): Run all checks in GitHub Actions workflow

## Configuration Files

### `.pre-commit-config.yaml`
Location: Root of `.github-private`
Purpose: Enforces repository safety checks and code quality
Updates: Rarely (only when adding/removing hooks)

### `.tflint.hcl.template`
Location: Root of `.github-private` (copied to modules)
Purpose: Template for TFLint configuration
Updates: When adding new rules or updating plugin versions

### `.checkov.yml.template`
Location: Root of `.github-private` (copied to modules)
Purpose: Template for Checkov security scanning
Updates: When adding skip rules or changing scan behavior

### `.terraform-docs.yml`
Location: Root of `.github-private` (copied to modules)
Purpose: Template for terraform-docs configuration
Updates: When changing documentation format/structure

## Best Practices

### For Module Developers

1. **Always run full validation suite** before creating PR
2. **Install pre-commit** in your local environment: `pre-commit install`
3. **Never skip Checkov** - security is critical
4. **Document traceability** - create matrix in PR description
5. **Test hooks** - verify pre-commit catches issues: `pre-commit run --all-files`

### For Repository Maintainers

1. **Keep templates up-to-date** - sync with latest tool versions
2. **Review pre-commit config** - ensure hooks remain relevant
3. **Monitor validation failures** - identify patterns for new rules
4. **Update documentation** - keep this file current with any changes

## Troubleshooting

### Pre-commit hook not running

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install

# Clear cache and reinstall
pre-commit clean
pre-commit install --install-hooks
```

### Pre-commit hook blocking valid change

```bash
# Skip hooks for specific commit (use sparingly!)
git commit --no-verify -m "message"

# Better: Fix the issue or update .pre-commit-config.yaml
```

### Checkov too slow

```bash
# Use experimental flag to skip re-downloads
export CHECKOV_EXPERIMENTAL_TERRAFORM_MANAGED_MODULES=True

# Scan only changed files (not recommended for security)
checkov -f main.tf --framework terraform
```

## References

- [Pre-commit Framework](https://pre-commit.com/)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Checkov Documentation](https://www.checkov.io/)
- [terraform-docs Documentation](https://terraform-docs.io/)
- [HashiCorp Module Standards](https://developer.hashicorp.com/terraform/language/modules/develop/structure)

---

**Last Updated**: 2026-02-06
**Maintained By**: Platform Engineering Team
