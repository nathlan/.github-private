# Rollback Procedures

## Overview

This document provides step-by-step procedures for rolling back Azure infrastructure changes deployed via the Terraform CI/CD workflow. Rolling back infrastructure is inherently complex and should be approached with caution.

## ⚠️ Important Considerations

**Before initiating a rollback:**

1. **Assess the impact**: Understand what broke and the blast radius
2. **Consider alternatives**: Sometimes a forward fix is safer than a rollback
3. **Review dependencies**: Check if other systems depend on the new infrastructure
4. **Data implications**: Rollback may not restore deleted data or state
5. **Notify stakeholders**: Inform affected teams before and after rollback

## Rollback Methods

### Method 1: Revert Git Commit (Recommended)

**When to use**: Configuration changes, resource modifications (not deletions)

**Advantages**:
- Maintains audit trail
- Triggers normal CI/CD validation
- Safe and controlled process

**Steps**:

1. **Identify the problematic commit**:
   ```bash
   # View recent commits
   git log --oneline -10

   # Or search by date/author
   git log --since="2 hours ago" --oneline
   ```

2. **Create revert commit**:
   ```bash
   # Revert the specific commit
   git revert <commit-sha>

   # For example
   git revert abc1234
   ```

3. **Push to branch and create PR**:
   ```bash
   # Create rollback branch
   git checkout -b rollback/revert-<commit-sha>

   # Push to GitHub
   git push origin rollback/revert-<commit-sha>
   ```

4. **Create pull request**:
   - Title: `Rollback: <description of change being reverted>`
   - Description: Reference original PR, describe issue, link to incident
   - Label: `rollback`, `urgent`

5. **Review the plan**:
   - Workflow will automatically run validation and generate plan
   - Review plan output in PR comment
   - Ensure it will restore previous state

6. **Merge and deploy**:
   - Get expedited approval if needed
   - Merge to `main`
   - Approve deployment when prompted
   - Monitor logs during apply

7. **Verify rollback**:
   - Check that infrastructure is back to expected state
   - Run smoke tests
   - Monitor application metrics

### Method 2: Restore from Previous Terraform State (Advanced)

**When to use**: Emergency situations where Method 1 is not feasible

**⚠️ WARNING**: This method bypasses normal CI/CD and should only be used in emergencies

**Prerequisites**:
- Azure CLI access
- Access to Terraform state storage account
- Terraform CLI installed locally

**Steps**:

1. **Download previous state file**:
   ```bash
   # Set variables
   STORAGE_ACCOUNT="tfstate12345"
   CONTAINER_NAME="tfstate"
   STATE_FILE="production.terraform.tfstate"

   # Login to Azure
   az login

   # List state versions (if versioning enabled)
   az storage blob list \
     --account-name ${STORAGE_ACCOUNT} \
     --container-name ${CONTAINER_NAME} \
     --prefix ${STATE_FILE} \
     --auth-mode login

   # Download specific version
   az storage blob download \
     --account-name ${STORAGE_ACCOUNT} \
     --container-name ${CONTAINER_NAME} \
     --name ${STATE_FILE} \
     --file ./backup.tfstate \
     --auth-mode login
   ```

2. **Review the backup state**:
   ```bash
   # View resources in backup state
   terraform state list -state=backup.tfstate

   # Compare with current state
   cd terraform/
   terraform state list
   ```

3. **Create rollback plan**:
   ```bash
   # Initialize Terraform
   terraform init

   # Replace current state (creates automatic backup)
   cp backup.tfstate terraform.tfstate

   # Generate plan to restore previous state
   terraform plan -out=rollback.tfplan
   ```

4. **Review and apply**:
   ```bash
   # Carefully review the plan
   terraform show rollback.tfplan

   # If plan looks correct, apply
   terraform apply rollback.tfplan
   ```

5. **Update Git repository**:
   ```bash
   # Revert Terraform code to match restored state
   git revert <commit-sha>
   git push origin main
   ```

### Method 3: Manual Resource Restoration (Last Resort)

**When to use**: Single resource issues, surgical fixes needed

**⚠️ WARNING**: Can cause state drift. Sync with Terraform afterward.

**Steps**:

1. **Identify the specific resource**:
   ```bash
   # List resources in state
   cd terraform/
   terraform state list
   ```

2. **Get previous configuration**:
   ```bash
   # View resource at previous commit
   git show <commit-sha>:terraform/main.tf
   ```

3. **Use Azure Portal or CLI to restore**:
   - Azure Portal: Manually revert configuration
   - Azure CLI: Script the changes

   Example for VM size change:
   ```bash
   az vm resize \
     --resource-group my-rg \
     --name my-vm \
     --size Standard_D2s_v3
   ```

4. **Sync Terraform state**:
   ```bash
   # Refresh state from Azure
   terraform refresh

   # Or import resource if recreated
   terraform import azurerm_virtual_machine.example /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/myvm
   ```

5. **Update code to match**:
   ```bash
   # Revert the code
   git revert <commit-sha>
   git push origin main
   ```

## Rollback Decision Tree

```
┌─────────────────────────────┐
│ Is production broken?       │
└─────────┬───────────────────┘
          │
    ┌─────▼─────┐
    │ Yes │ No  │
    └──┬──┴──┬──┘
       │     │
       │     └──► Forward fix (preferred)
       │
       ▼
┌──────────────────────────────┐
│ Is it a config change only?  │
│ (no resource deletion)       │
└──────┬───────────────────────┘
       │
   ┌───▼───┐
   │ Yes   │ No
   └───┬───┴───┬───────────────┐
       │       │               │
       ▼       ▼               ▼
   Method 1  Can wait    Emergency?
   (Revert) 2-4 hours?        │
              │            ┌───▼───┐
          ┌───▼───┐        │ Yes   │ No
          │ Yes   │ No     └───┬───┴───┬────┐
          └───┬───┴───┬────    │       │    │
              │       │         ▼       ▼    ▼
              ▼       ▼     Method 2  Engage   Method 1
          Method 1  Method 3  (State   Incident (with
          (Revert)  (Manual)  Restore) Response expedited
                                       Team     approval)
```

## Rollback Checklist

### Pre-Rollback

- [ ] Incident declared and documented
- [ ] Stakeholders notified
- [ ] Impact assessment completed
- [ ] Rollback method chosen
- [ ] Rollback plan documented
- [ ] Communication plan in place
- [ ] Backup of current state saved (if using Method 2 or 3)

### During Rollback

- [ ] Changes reverted in version control
- [ ] Plan reviewed and validated
- [ ] Approval obtained (if required)
- [ ] Rollback executed
- [ ] Logs captured
- [ ] Monitoring in place

### Post-Rollback

- [ ] Infrastructure state verified
- [ ] Application functionality tested
- [ ] Monitoring dashboards checked
- [ ] Stakeholders notified of completion
- [ ] Incident postmortem scheduled
- [ ] Root cause analysis initiated
- [ ] Documentation updated
- [ ] Lessons learned captured

## Testing Rollback Procedures

**Recommendation**: Test rollback procedures in non-production environments regularly.

### Rollback Drill Process

1. **Schedule drill**: Announce to team, pick non-critical time
2. **Deploy test change**: Make a controlled change to staging environment
3. **Execute rollback**: Use Method 1 (revert commit)
4. **Measure time**: Track how long rollback takes
5. **Document issues**: Note any problems encountered
6. **Refine procedures**: Update this document based on learnings
7. **Train team**: Share results and best practices

### Sample Drill Schedule

- **Monthly**: Quick revert drill in development environment
- **Quarterly**: Full rollback drill in staging environment
- **Annually**: Disaster recovery drill with state restoration

## Common Scenarios

### Scenario 1: Broken Application Configuration

**Symptoms**: Application not working, infrastructure is fine

**Solution**:
- Use Method 1 (Revert Git Commit)
- Typically safe and fast
- Full validation pipeline runs

**Timeline**: 15-30 minutes

### Scenario 2: Resource Size/SKU Change Causing Issues

**Symptoms**: Performance degradation, cost spike

**Solution**:
- Use Method 1 if change was recent (< 4 hours)
- Use Method 3 for quick manual fix if urgent
- Sync state afterward

**Timeline**: 10-20 minutes (Method 3), 30-45 minutes (Method 1)

### Scenario 3: Accidental Resource Deletion

**Symptoms**: Critical resources missing

**Solution**:
- Check Azure backup/soft delete first
- Use Method 2 (State Restore) if backups exist
- May require manual recreation + import
- **Data may be lost**

**Timeline**: 1-4 hours (varies by resource complexity)

### Scenario 4: Network Configuration Breaking Connectivity

**Symptoms**: Cannot access resources, network isolated

**Solution**:
- Use Azure Portal to manually fix networking (Method 3)
- Then use Method 1 to revert code
- May need Azure support escalation

**Timeline**: 30 minutes - 2 hours

## Emergency Contacts

Maintain a list of key contacts for rollback scenarios:

| Role | Contact | When to Escalate |
|------|---------|------------------|
| Platform Team | [Team Slack/Email] | All rollbacks |
| Azure Administrators | [Contact Info] | Permissions, state access issues |
| Application Owners | [Contact Info] | Application impact assessment |
| Incident Commander | [On-call Info] | P0/P1 incidents |
| Security Team | [Contact Info] | Security-related changes |

## State Backup Strategy

### Automatic Backups

Azure Storage Account can be configured for:

1. **Blob Versioning** (Recommended):
   ```bash
   az storage account blob-service-properties update \
     --account-name ${STORAGE_ACCOUNT} \
     --enable-versioning true
   ```

2. **Soft Delete**:
   ```bash
   az storage account blob-service-properties update \
     --account-name ${STORAGE_ACCOUNT} \
     --enable-delete-retention true \
     --delete-retention-days 30
   ```

3. **Point-in-Time Restore**:
   ```bash
   az storage account blob-service-properties update \
     --account-name ${STORAGE_ACCOUNT} \
     --enable-restore-policy true \
     --restore-days 7
   ```

### Manual Backups

Consider scripting regular state backups:

```bash
#!/bin/bash
# backup-terraform-state.sh

DATE=$(date +%Y%m%d-%H%M%S)
STORAGE_ACCOUNT="tfstate12345"
CONTAINER="tfstate"
STATE_FILE="production.terraform.tfstate"
BACKUP_PATH="backups/terraform.tfstate.${DATE}"

az storage blob download \
  --account-name ${STORAGE_ACCOUNT} \
  --container-name ${CONTAINER} \
  --name ${STATE_FILE} \
  --file ${BACKUP_PATH} \
  --auth-mode login

echo "State backed up to: ${BACKUP_PATH}"
```

## Preventing the Need for Rollbacks

**Best Practices**:

1. **Thorough testing**: Test changes in development/staging first
2. **Small changes**: Deploy incremental changes, not large batches
3. **Feature flags**: Use feature flags for application config
4. **Blue/green deployments**: For major infrastructure changes
5. **Automated tests**: Implement comprehensive smoke tests
6. **Monitoring**: Set up alerts for key metrics
7. **Dry runs**: Use `terraform plan` extensively
8. **Peer review**: Always require PR approval
9. **Change windows**: Deploy during low-traffic periods
10. **Documentation**: Keep runbooks up to date

## References

- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)
- [Azure Blob Versioning](https://docs.microsoft.com/azure/storage/blobs/versioning-overview)
- [Git Revert Documentation](https://git-scm.com/docs/git-revert)
- [Incident Response Best Practices](https://www.pagerduty.com/resources/learn/incident-response-best-practices/)

---

**Remember**: Rolling back is sometimes necessary, but prevention is always better than cure. Invest in testing, monitoring, and incremental deployment practices.

**Emergency Rollback Hotline**: [Add your team's emergency contact info]
