# Landing Zone Module v3.0.0 - Azure Naming Integration and Smart Defaults

## Breaking Changes

This is a MAJOR version release with breaking changes. Existing users will need to migrate their configurations.

## Key Features

- **Azure Naming Module Integration**: All resources (except subscriptions/budgets/RGs) use Azure naming conventions
- **Time Provider for Budgets**: Idempotent budget timestamps using time_static and time_offset
- **Smart Defaults**: 70% code reduction (95 → 25 lines per landing zone)
- **Landing Zones Map**: Support multiple landing zones in single module call
- **Flattened Networking**: Simplified VNet structure (always 1 spoke per LZ)
- **Subnet Support**: Automatic CIDR calculation from VNet address space
- **Environment Validation**: Only dev, test, or prod allowed
- **3-Layer Tag Merging**: Common + auto-generated + custom tags

## Naming Patterns

### Custom Naming (NOT in naming module)
- **Subscriptions**: `sub-{workload}-{env}`
- **Resource Groups**: `rg-{purpose}-{workload}-{env}` (purpose FIRST!)
- **Budgets**: `budget-{workload}-{env}`

### Azure Naming Module
- **Virtual Networks**: `vnet-{workload}-{env}`
- **Subnets**: `snet-{workload}-{env}-{name}`
- **User Assigned Identities**: `id-{workload}-{env}-{purpose}`

## Migration Required

Existing v2.x users must:
1. Add time provider to versions.tf
2. Restructure to landing_zones map
3. Remove manual resource naming
4. Update budget configuration format
5. Update VNet configuration (flattened)

See CHANGELOG.md for detailed migration guide.

## Validation

✅ terraform init -backend=false  
✅ terraform fmt -recursive  
✅ terraform validate  
✅ All naming patterns verified

## Breaking Changes Summary

- New `landing_zones` map variable structure
- Time provider required (hashicorp/time >= 0.9, < 1.0)
- Auto-generated resource names (cannot override)
- Environment validation enforced (dev/test/prod only)
- Subscription scope for UMI role assignments
