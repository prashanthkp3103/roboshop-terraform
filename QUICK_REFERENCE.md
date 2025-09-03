# RoboShop Terraform - Quick Reference Guide

## 🚀 Quick Start

### Prerequisites Checklist
- [ ] AWS CLI configured with proper credentials
- [ ] Terraform installed (v0.12+)
- [ ] S3 bucket created for state storage
- [ ] Route53 hosted zone setup
- [ ] Valid ACM certificate (for HTTPS)

### Deploy Development Environment
```bash
# Clone repository
git clone <repository-url>
cd roboshop-terraform-ec2-r53-asg-alb-single-public-and-multiple-internal--acm

# Update configuration
vim env-dev/main.tfvars
# Update: bastion_node, zone_id, vault_token

# Deploy infrastructure
bash run.sh dev apply
```

## 📋 Common Operations

### Environment Management
```bash
# Deploy
bash run.sh dev apply     # Development
bash run.sh prod apply    # Production

# Destroy
bash run.sh dev destroy   # Development
bash run.sh prod destroy  # Production

# Plan changes
terraform init -backend-config=env-dev/state.tfvars
terraform plan -var-file=env-dev/main.tfvars
```

### Scaling Applications
```bash
# Edit capacity in env-dev/main.tfvars
apps = {
  frontend = {
    capacity = {
      desired = 2  # Changed from 1
      max     = 4  # Changed from 1
      min     = 1
    }
  }
}

# Apply changes
bash run.sh dev apply
```

### Adding New Services
```bash
# Add to apps map in env-dev/main.tfvars
apps = {
  # ... existing services ...
  
  new-service = {
    subnet_ref       = "app"
    instance_type    = "t3.small"
    allow_port       = 8080
    allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"]
    allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24"]
    capacity = {
      desired = 1
      max     = 2
      min     = 1
    }
    lb_internal   = true
    lb_subnet_ref = "app"
    acm_http_arn  = null
  }
}

# Apply changes
bash run.sh dev apply
```

## 🔧 Configuration Templates

### Basic Service Configuration
```hcl
service-name = {
  subnet_ref       = "app"           # app, web, or db
  instance_type    = "t3.small"      # EC2 instance type
  allow_port       = 8080            # Application port
  allow_sg_cidr    = ["10.10.4.0/24", "10.10.5.0/24"]  # Allowed source CIDRs
  allow_lb_sg_cidr = ["10.10.2.0/24", "10.10.3.0/24"]  # LB access CIDRs
  capacity = {
    desired = 1                      # Desired instance count
    max     = 3                      # Maximum instances
    min     = 1                      # Minimum instances
  }
  lb_internal   = true               # Internal (true) or Internet-facing (false)
  lb_subnet_ref = "app"              # LB subnet placement
  acm_http_arn  = null               # ACM certificate ARN (for HTTPS)
}
```

### Database Configuration
```hcl
database-name = {
  subnet_ref      = "db"             # Always use db subnets
  instance_type   = "t3.small"       # Instance size
  allow_port      = 5432             # Database port
  allow_sg_cidr   = ["10.10.4.0/24", "10.10.5.0/24"]  # App subnet access
}
```

## 🔍 Troubleshooting

### Check Instance Status
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*-dev" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### View Load Balancer Health
```bash
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code,DNSName]' \
  --output table
```

### Check Auto Scaling Groups
```bash
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[*].[AutoScalingGroupName,DesiredCapacity,Instances[0].HealthStatus]' \
  --output table
```

### View Security Groups
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*-dev-*" \
  --query 'SecurityGroups[*].[GroupName,GroupId]' \
  --output table
```

## 🛠️ Maintenance Tasks

### Update AMI
1. Find latest AMI ID
2. Update `data.tf` in modules if needed
3. Apply terraform to cycle instances

### Scale Services
1. Update `capacity` in tfvars
2. Apply terraform
3. Monitor scaling in AWS console

### Update Security Groups
1. Modify `allow_sg_cidr` in tfvars
2. Apply terraform
3. Verify connectivity

### Certificate Renewal
1. Request new certificate in ACM
2. Update `acm_http_arn` in tfvars
3. Apply terraform

## 📊 Monitoring Commands

### CloudWatch Logs
```bash
# View application logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2"

# Tail specific service logs
aws logs tail /var/log/messages --follow
```

### System Metrics
```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --statistics Average \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 3600
```

## 🚨 Emergency Procedures

### Service Down
1. Check ALB target health
2. Verify ASG instance health
3. Check CloudWatch logs
4. Restart unhealthy instances if needed

### Scale Up Immediately
```bash
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name frontend-dev \
  --desired-capacity 3
```

### Security Incident
1. Isolate affected instances
2. Update security groups to block traffic
3. Investigate logs
4. Update configurations and redeploy

## 📞 Getting Help

### Log Locations
- Application logs: `/opt/userdata.log`
- System logs: `/var/log/messages`
- Service logs: `/var/log/<service-name>/`

### Useful AWS Console Pages
- EC2 → Instances
- EC2 → Load Balancers  
- EC2 → Auto Scaling Groups
- CloudWatch → Logs
- Route53 → Hosted Zones

### Common Error Solutions
- **Instance launch failed**: Check AMI availability and instance limits
- **Health check failed**: Verify application port and security groups
- **DNS resolution failed**: Check Route53 configuration
- **SSL errors**: Verify ACM certificate and ALB listeners