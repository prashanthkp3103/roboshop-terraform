# CI/CD Pipeline Documentation

## 🚀 GitHub Actions Workflows

This repository includes GitHub Actions workflows for automated deployment and destruction of the RoboShop infrastructure.

### Available Workflows

#### 1. Infrastructure Creation (`create.yml`)
- **Trigger**: Manual dispatch (`workflow_dispatch`)
- **Purpose**: Deploy the complete RoboShop infrastructure
- **Runner**: Self-hosted runner
- **Environment**: Development

**Workflow Steps**:
1. Checkout repository code
2. Initialize Terraform with development backend
3. Apply Terraform configuration with auto-approval

**Usage**:
- Navigate to Actions tab in GitHub repository
- Select "Roboshop Terraform Creation" workflow
- Click "Run workflow" button
- Confirm execution

#### 2. Infrastructure Destruction (`destroy.yml`)
- **Trigger**: Manual dispatch (`workflow_dispatch`)
- **Purpose**: Destroy the complete RoboShop infrastructure
- **Runner**: Self-hosted runner
- **Environment**: Development

**Workflow Steps**:
1. Checkout repository code
2. Initialize Terraform with development backend
3. Destroy Terraform-managed resources with auto-approval

**Usage**:
- Navigate to Actions tab in GitHub repository
- Select "Roboshop Terraform Destroy" workflow
- Click "Run workflow" button
- ⚠️ **Confirm destruction** - This will delete all resources!

## 🔧 Required Secrets

Configure the following secrets in your GitHub repository:

### `VAULT_TOKEN`
- **Description**: HashiCorp Vault token for secrets management
- **Usage**: Used by Terraform to authenticate with Vault for retrieving sensitive configuration
- **Format**: Vault token string

**To add secrets**:
1. Go to repository Settings
2. Navigate to Security → Secrets and variables → Actions
3. Click "New repository secret"
4. Add `VAULT_TOKEN` with your vault token value

## 🏃‍♂️ Self-Hosted Runner Configuration

The workflows use self-hosted runners for security and network access reasons.

### Setup Requirements
1. **Runner Installation**: Install GitHub Actions runner on your infrastructure
2. **Network Access**: Runner must have access to AWS APIs and your private networks
3. **Tools Installation**: 
   - Terraform CLI
   - AWS CLI
   - Git

### Runner Configuration
```bash
# Download and extract runner
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.310.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.310.2/actions-runner-linux-x64-2.310.2.tar.gz
tar xzf ./actions-runner-linux-x64-2.310.2.tar.gz

# Configure runner
./config.sh --url https://github.com/your-username/your-repo --token YOUR_TOKEN

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
```

## 🔒 Security Considerations

### Access Control
- Workflows use manual triggers only (`workflow_dispatch`)
- No automatic deployments on code push
- Requires appropriate GitHub repository permissions

### Credential Management
- Vault token stored as GitHub secret
- No hardcoded credentials in workflow files
- AWS credentials managed through runner's IAM role/profile

### Network Security
- Self-hosted runner provides secure access to private networks
- No exposure of sensitive endpoints to GitHub-hosted runners

## 📊 Monitoring Workflow Execution

### Viewing Logs
1. Navigate to Actions tab in GitHub repository
2. Click on the specific workflow run
3. Expand job steps to view detailed logs
4. Check Terraform output for resource status

### Common Issues and Solutions

#### Workflow Failures
- **Authentication Issues**: Check Vault token validity
- **Permission Errors**: Verify AWS credentials and permissions
- **Resource Conflicts**: Check for existing resources or state lock

#### Runner Issues
- **Runner Offline**: Check runner service status
- **Tool Missing**: Ensure all required tools are installed
- **Network Issues**: Verify connectivity to AWS and GitHub

## 🔄 Workflow Customization

### Adding Environments
To add production or staging workflows:

1. **Create new workflow file** (e.g., `prod-create.yml`)
2. **Update backend configuration**: Use prod state backend
3. **Update variable file**: Use `env-prod/main.tfvars`
4. **Add environment protection**: Configure GitHub environments

### Example Production Workflow
```yaml
name: Roboshop Terraform Production Deploy

on: 
  workflow_dispatch:
    inputs:
      confirm_production:
        description: 'Type "PRODUCTION" to confirm deployment'
        required: true
        default: ''

jobs:
  Production-Deploy:
    runs-on: self-hosted
    environment: production
    if: github.event.inputs.confirm_production == 'PRODUCTION'
    steps:
      - uses: actions/checkout@v4
      - name: Terraform init
        run: terraform init -backend-config=env-prod/state.tfvars
      - name: Terraform apply
        run: terraform apply -var-file=env-prod/main.tfvars -auto-approve -var vault_token=${{ secrets.VAULT_TOKEN }}
```

### Adding Approval Gates
Configure GitHub environments with required reviewers:

1. Go to repository Settings
2. Navigate to Environments
3. Create new environment (e.g., "production")
4. Add required reviewers
5. Set deployment protection rules

## 📋 Best Practices

### Pre-Deployment Checklist
- [ ] Verify Vault token validity
- [ ] Check AWS service limits
- [ ] Review terraform plan output
- [ ] Confirm backup procedures
- [ ] Notify team of deployment

### Post-Deployment Verification
- [ ] Check application endpoints
- [ ] Verify auto-scaling functionality
- [ ] Test load balancer health checks
- [ ] Confirm DNS resolution
- [ ] Monitor CloudWatch metrics

### Rollback Procedures
1. **Immediate Issues**: Use destroy workflow to remove problematic resources
2. **Partial Rollback**: Use terraform destroy with targeting
3. **Application Issues**: Deploy previous application version through Ansible

## 🚨 Emergency Procedures

### Failed Deployment
1. Check workflow logs for specific errors
2. Verify resource state in AWS console
3. Use terraform state commands to investigate
4. Consider manual intervention if needed

### Resource Cleanup
If workflows fail to destroy resources:
```bash
# Manual cleanup steps
terraform init -backend-config=env-dev/state.tfvars
terraform destroy -var-file=env-dev/main.tfvars -target=module.specific_module
```

### State Recovery
For corrupted terraform state:
1. Backup current state file
2. Use terraform import to recover resources
3. Verify state consistency
4. Resume normal operations

This CI/CD setup provides a secure, controlled way to manage your RoboShop infrastructure deployment lifecycle.