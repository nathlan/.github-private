# Terraform-docs Binary

This repository includes `terraform-docs.tar.gz` which contains the terraform-docs binary used by the agent.

## Important: Safe Extraction

The archive contains additional files (LICENSE, README.md) that would overwrite repository files if extracted directly.

**To extract safely, use one of these methods:**

### Option 1: Extract only the binary (recommended)
```bash
tar -xzf terraform-docs.tar.gz terraform-docs
```

### Option 2: Extract to a tools directory
```bash
mkdir -p tools
tar -xzf terraform-docs.tar.gz -C tools
export PATH="$PWD/tools:$PATH"
```

### Option 3: Extract specific file to /usr/local/bin (requires sudo)
```bash
sudo tar -xzf terraform-docs.tar.gz -C /usr/local/bin terraform-docs
```

## DO NOT DO THIS

❌ **Never extract the entire archive in the repository root:**
```bash
tar -xzf terraform-docs.tar.gz  # This will overwrite LICENSE and README.md!
```

## Updating terraform-docs

To update to a new version:

1. Download the new release from https://github.com/terraform-docs/terraform-docs/releases
2. Replace `terraform-docs.tar.gz` in this repository
3. The archive format should remain consistent (contains terraform-docs binary, LICENSE, and README.md)
