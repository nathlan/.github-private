# TFLint Configuration for Azure Terraform
# https://github.com/terraform-linters/tflint

config {
  # Format: default, json, checkstyle, junit, compact, sarif
  format = "default"

  # Enable/disable colored output
  force = false

  # Disable default rules
  disabled_by_default = false

  # Plugin directory
  plugin_dir = "~/.tflint.d/plugins"

  # Ignore specific modules
  # ignore_module = {
  #   "terraform-aws-modules/vpc/aws" = true
  # }

  # Variables file
  # varfile = ["example.tfvars"]

  # Variables
  # variables = ["foo=bar", "baz=qux"]
}

# Azure Provider Plugin
# https://github.com/terraform-linters/tflint-ruleset-azurerm
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Terraform Core Rules
# https://github.com/terraform-linters/tflint-ruleset-terraform

# Disallow deprecated interpolation syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow legacy dot index syntax
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow variables, data sources, and locals that are declared but never used
rule "terraform_unused_declarations" {
  enabled = true
}

# Require that all providers have version constraints through required_providers
rule "terraform_required_providers" {
  enabled = true
}

# Ensure that a module version is specified for all referenced modules
rule "terraform_required_version" {
  enabled = true
}

# Disallow specifying a git or mercurial repository as a module source without pinning to a version
rule "terraform_module_pinned_source" {
  enabled = true
  # style = "flexible" # or "semver"
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Resource naming
  resource {
    format = "snake_case"
    # custom = "^[a-z][a-z0-9_]*$"
  }

  # Variable naming
  variable {
    format = "snake_case"
  }

  # Output naming
  output {
    format = "snake_case"
  }

  # Local values naming
  locals {
    format = "snake_case"
  }

  # Module naming
  module {
    format = "snake_case"
  }

  # Data source naming
  data {
    format = "snake_case"
  }
}

# Disallow // comments in favor of #
rule "terraform_comment_syntax" {
  enabled = true
}

# Disallow output declarations without description
rule "terraform_documented_outputs" {
  enabled = true
}

# Disallow variable declarations without description
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow variable declarations without type
rule "terraform_typed_variables" {
  enabled = true
}

# Ensure that all modules sourced from a registry specify a version
rule "terraform_standard_module_structure" {
  enabled = false  # Can be strict for large projects
}

# Disallow terraform declarations without required_version
rule "terraform_workspace_remote" {
  enabled = false  # Not applicable for all setups
}

# Azure-Specific Rules (enforced by azurerm plugin)
# These are automatically enabled when the plugin is active:
#
# - Validate resource SKUs/sizes exist
# - Validate region/location names
# - Validate VM sizes
# - Validate storage account names (globally unique, length, characters)
# - Validate resource group names
# - Validate other Azure-specific constraints
#
# See: https://github.com/terraform-linters/tflint-ruleset-azurerm/tree/main/docs/rules

# Custom Rules (if you have custom rulesets)
# plugin "custom" {
#   enabled = true
#   source  = "github.com/your-org/tflint-ruleset-custom"
#   version = "0.1.0"
# }

# Rule Customization Examples:

# Disable specific rules if needed
# rule "azurerm_resource_missing_tags" {
#   enabled = false
# }

# Configure specific rule behavior
# rule "terraform_module_pinned_source" {
#   enabled = true
#   style   = "semver"  # Require semantic versioning
# }

# Ignore specific files or directories
# You can use .tflintignore file instead
# Example .tflintignore:
# **/.terraform/**
# **/examples/**
# **/tests/**
