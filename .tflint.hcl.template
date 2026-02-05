# TFLint Configuration for Terraform Modules
# https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md

# Terraform core linting with recommended preset
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Azure-specific validation rules
plugin "azurerm" {
  enabled = true
  version = "0.25.1"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Enforce naming conventions (snake_case for all identifiers)
rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }
}

# Require documentation for all outputs and variables
rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}
