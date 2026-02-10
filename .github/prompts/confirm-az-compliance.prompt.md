---
name: confirm az compliance
description: Check this repo against shared compliance standards and report results in chat
target-agent: az-compliance
---

# Confirm AZ Compliance

Run a compliance check against `nathlan/shared-standards` and report the results here in chat.

## Scope

Tell me what to scan:
- **Changed files** (default)
- **Full repo**
- **Specific paths** (list files or folders)

## Optional details

- Any specific standard sections or technologies to focus on
- Whether to include unstaged changes

## Example

- "Check changed files only"
- "Scan full repo, focus on Terraform and YAML"
- "Only scan docs/ and .github/workflows"
