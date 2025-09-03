# RoboShop E-commerce Platform - Terraform Infrastructure

This repository contains Terraform infrastructure code for deploying a scalable, multi-tier RoboShop e-commerce application on AWS. The architecture implements a robust 3-tier application with proper security isolation, auto-scaling capabilities, and load balancing.

## 🏗️ Architecture Overview

The infrastructure deploys a complete e-commerce platform with the following components:

### **Network Architecture**
- **VPC**: Custom VPC with CIDR `10.10.0.0/16`
- **Multi-AZ Deployment**: Spans across `us-east-1a` and `us-east-1b`
- **Subnet Layout**:
  - **Public Subnets**: `10.10.0.0/24`, `10.10.1.0/24` (Internet-facing resources)
  - **Web Subnets**: `10.10.2.0/24`, `10.10.3.0/24` (Web tier)  
  - **App Subnets**: `10.10.4.0/24`, `10.10.5.0/24` (Application tier)
  - **DB Subnets**: `10.10.6.0/24`, `10.10.7.0/24` (Database tier)

### **Application Components**

#### **Frontend Service**
- **Type**: Public-facing web application
- **Load Balancer**: Internet-facing ALB in public subnets
- **Auto Scaling**: t3.small instances in web subnets
- **SSL/TLS**: ACM certificate for HTTPS termination
- **Port**: 80/443

#### **Microservices** (Internal)
- **catalogue**: Product catalog service
- **cart**: Shopping cart management
- **user**: User authentication and management
- **shipping**: Order shipping logic
- **payment**: Payment processing
- **dispatch**: Order dispatch service

All microservices:
- Run on t3.small instances in app subnets
- Have internal ALBs for inter-service communication
- Auto-scale based on demand
- Listen on port 8080

#### **Database Services**
- **MongoDB**: Document store for product catalog and user data
- **MySQL**: Relational database for transactional data
- **Redis**: Caching and session storage
- **RabbitMQ**: Message queue for asynchronous processing

All databases:
- Run on t3.small instances in private DB subnets
- Only accessible from application tier
- No direct internet access

## 🔒 Security Model

### **Network Security**
- **Defense in Depth**: Multi-layer security with subnet isolation
- **Security Groups**: Restrictive inbound/outbound rules per tier
- **Bastion Access**: SSH access only from designated bastion host
- **No Direct Access**: Database tier isolated from internet

### **Access Control**
- **Bastion Host**: Single entry point for SSH access (`172.31.16.106/32`)
- **Port Restrictions**: Each service only exposes necessary ports
- **CIDR-based Rules**: Subnet-level access controls

### **SSL/TLS**
- **ACM Integration**: AWS Certificate Manager for SSL certificates
- **HTTPS Termination**: Load balancer level SSL termination
- **Secure Communication**: Internal traffic encryption

## 📁 Repository Structure

```
├── main.tf                 # Root module orchestration
├── variables.tf            # Root module variables
├── state.tf               # Remote state configuration
├── run.sh                 # Deployment automation script
├── Makefile              # Build automation
├── env-dev/              # Development environment
│   ├── main.tfvars       # Environment-specific variables
│   └── state.tfvars      # Remote state backend config
├── env-prod/             # Production environment
│   ├── main.tfvars       # Production variables
│   ├── state.tfvars      # Production state config
│   └── provide.tf        # Provider configuration
└── modules/              # Reusable Terraform modules
    ├── vpc/              # VPC and networking
    ├── asg/              # Auto Scaling Groups with ALB
    └── ec2/              # EC2 instances for databases
```

## 🚀 Prerequisites

1. **AWS Account**: Valid AWS account with appropriate permissions
2. **Terraform**: Version 0.12+ installed
3. **AWS CLI**: Configured with proper credentials
4. **S3 Bucket**: For remote state storage (`d80-terraform-ppk`)
5. **Route53 Domain**: For DNS management
6. **HashiCorp Vault**: For secrets management (optional)

## 📋 Required AWS Permissions

Ensure your AWS credentials have permissions for:
- VPC and subnet creation/management
- EC2 instance creation and management
- Auto Scaling Groups and Launch Templates
- Application Load Balancers and Target Groups
- Security Groups and NACLs
- Route53 hosted zones and records
- ACM certificate management
- S3 bucket access for state storage

## 🛠️ Deployment Instructions

### **Option 1: Using the Run Script**

```bash
# Deploy development environment
bash run.sh dev apply

# Deploy production environment  
bash run.sh prod apply

# Destroy development environment
bash run.sh dev destroy

# Destroy production environment
bash run.sh prod destroy
```

### **Option 2: Using Makefile**

```bash
# Development environment
make dev-apply      # Deploy
make dev-destroy    # Destroy

# Production environment
make prod-apply     # Deploy  
make prod-destroy   # Destroy
```

### **Option 3: Manual Terraform Commands**

```bash
# Initialize backend
terraform init -backend-config=env-dev/state.tfvars

# Plan deployment
terraform plan -var-file=env-dev/main.tfvars

# Apply changes
terraform apply -var-file=env-dev/main.tfvars --auto-approve

# Destroy infrastructure
terraform destroy -var-file=env-dev/main.tfvars --auto-approve
```

## ⚙️ Configuration

### **Environment Variables**

Update `env-dev/main.tfvars` or `env-prod/main.tfvars`:

```hcl
env = "dev"
bastion_node = ["YOUR_IP/32"]
zone_id = "YOUR_ROUTE53_ZONE_ID"
vault_token = "YOUR_VAULT_TOKEN"  # Optional

vpc = {
  cidr = "10.10.0.0/16"
  # ... other VPC settings
}
```

### **Backend Configuration**

Update `env-dev/state.tfvars`:

```hcl
bucket = "your-terraform-state-bucket"
key    = "roboshop-tf/dev/terraform.tfstate"
region = "us-east-1"
```

## 🔄 Auto Scaling Configuration

Each application component supports auto scaling:

```hcl
capacity = {
  desired = 1    # Desired instance count
  max     = 3    # Maximum instances
  min     = 1    # Minimum instances
}
```

## 📊 Monitoring and Observability

- **CloudWatch**: Automatic metrics for ASG and ALB
- **Health Checks**: ALB health checks for all services
- **Auto Recovery**: Automatic instance replacement on failure
- **Scaling Metrics**: CPU and request-based scaling triggers

## 🔧 Customization

### **Adding New Services**

1. Add service configuration to `apps` map in `main.tfvars`
2. Define subnet placement, ports, and scaling parameters
3. Apply terraform to deploy

### **Database Modifications**

1. Update `db` map in `main.tfvars`
2. Modify instance types, ports, or access rules
3. Apply changes through terraform

## 🚨 Important Notes

- **State Management**: Uses S3 backend for state storage
- **Secrets**: Vault integration for sensitive data
- **Automation**: Ansible-pull used for application deployment
- **Multi-Environment**: Separate configurations for dev/prod
- **SSL Certificates**: Requires valid ACM certificates for HTTPS

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes and test
4. Submit pull request

## 📞 Support

For issues and questions:
- Check the AWS CloudWatch logs
- Verify security group rules
- Ensure proper IAM permissions
- Review terraform state for conflicts

---

**⚠️ Cost Warning**: This infrastructure will incur AWS charges. Monitor your usage and destroy resources when not needed.
