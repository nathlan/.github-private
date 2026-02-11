# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Azure Naming Module Integration**: Automatic resource naming using Azure/naming/azurerm ~> 0.4.3
- **Smart Defaults**: Pre-configured sensible defaults for common deployment patterns
- **Simplified Landing Zone Interface**: New `landing_zones` map variable replacing verbose per-resource configuration
- **Primary Variables**: `workload`, `env`, `team`, `location` at landing zone level
- **Automatic Resource Naming**:
  - Subscriptions: `sub-{workload}-{env}`
  - Resource Groups: `rg-{workload}-{env}-identity`, `rg-{workload}-{env}-network`
  - Virtual Networks: Auto-generated from naming module
  - Budgets: `budget-{workload}-{env}`
  - User-Managed Identities: Auto-generated from naming module
- **Environment Validation**: Only `dev`, `test`, `prod` allowed
- **Simplified Budget Configuration**: User provides amount, threshold, and emails; module auto-generates time periods and notifications using time provider
- **Time Provider Integration**: Budget dates now use `time_static` and `time_offset` resources for consistent timestamps
- **Tag Merging**: Automatic merging of common, auto-generated (`env`, `workload`, `team`), and user-provided tags
- **GitHub OIDC Simplification**: User provides repository name; module auto-generates credential configuration
- **Subscription DevTest Support**: New `subscription_devtest_enabled` boolean replacing `subscription_workload` string

### Changed
- **Breaking**: Refactored entire module interface from pass-through to opinionated wrapper
- **Breaking**: Replaced individual resource configuration maps with single `landing_zones` map
- **Breaking**: Changed from single landing zone to multi-landing zone support via `for_each`
- **Breaking**: IP address automation now at common level with `base_address_space`
- **Breaking**: Virtual networks use `address_space_required` (e.g., "/24") instead of full address space arrays
- **Breaking**: Budget time periods now use time provider resources (time_static, time_offset) instead of timestamp()/timeadd() functions
- Module outputs now structured by landing zone key
- Budget configuration uses time provider for consistent, idempotent timestamps
- Federated credentials use common `github_organization` variable
- Added time provider to required_providers (hashicorp/time >= 0.9, < 1.0)

### Removed
- **Breaking**: Individual boolean flags (`subscription_alias_enabled`, `resource_group_creation_enabled`, etc.) - now auto-enabled based on configuration
- **Breaking**: Manual resource naming - all names auto-generated
- **Breaking**: Per-resource location configuration - uses landing zone `location` by default
- IP address automation per-landing-zone variables - replaced with common `base_address_space`

## [0.1.0] - Previous Release

### Added
- Initial wrapper module for Azure Verified Module ALZ Subscription Vending
- IP address automation support using avm-utl-network-ip-addresses module
- Support for subscription creation, resource groups, virtual networks
- User-Managed Identity with federated credentials
- Budget configuration
- Pass-through interface to AVM module

[Unreleased]: https://github.com/nathlan/terraform-azurerm-landing-zone-vending/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nathlan/terraform-azurerm-landing-zone-vending/releases/tag/v0.1.0
