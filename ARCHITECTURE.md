# RoboShop Infrastructure Architecture Deep Dive

## 🏛️ Detailed Architecture Breakdown

### Network Topology

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Internet Gateway                         │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│               Public Subnets (10.10.0.0/24, 10.10.1.0/24) │
│                     [Frontend ALB]                          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                Web Subnets (10.10.2.0/24, 10.10.3.0/24)   │
│                    [Frontend Instances]                     │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│               App Subnets (10.10.4.0/24, 10.10.5.0/24)    │
│          [Microservices + Internal ALBs]                   │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                DB Subnets (10.10.6.0/24, 10.10.7.0/24)    │
│              [MongoDB, MySQL, Redis, RabbitMQ]             │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Traffic Flow

### 1. External User Request
```
Internet → Internet Gateway → Public ALB → Frontend Instances (Web Subnets)
```

### 2. Internal Service Communication
```
Frontend → Internal ALB (App Subnets) → Microservice Instances → Database (DB Subnets)
```

### 3. Administrative Access
```
Bastion Host → Target Instances (via SSH on port 22)
```

## 🗺️ Module Breakdown

### VPC Module (`modules/vpc/`)

**Purpose**: Creates the foundational network infrastructure

**Resources Created**:
- 1 VPC with custom CIDR
- 8 Subnets across 2 AZs (4 tiers × 2 AZs)
- Internet Gateway
- Route Tables and Routes
- VPC Peering (to default VPC)

**Outputs**:
- `vpc_id`: VPC identifier
- `subnets`: Map of subnet IDs by tier
- Individual subnet arrays by type

### ASG Module (`modules/asg/`)

**Purpose**: Creates auto-scaling application services with load balancers

**Resources Per Service**:
- Launch Template with user data
- Auto Scaling Group (1-3 instances)
- Application Load Balancer
- Target Group
- Security Groups (for instances and ALB)
- Route53 DNS records

**Key Features**:
- Automatic instance replacement
- Health check integration
- SSL termination (for public services)
- Dynamic scaling based on metrics

### EC2 Module (`modules/ec2/`)

**Purpose**: Creates standalone database instances

**Resources Per Database**:
- EC2 Instance
- Security Group
- Route53 DNS record
- EBS volumes (if configured)

**Database Services**:
- **MongoDB** (Port 27017): Document store
- **MySQL** (Port 3306): Relational database  
- **Redis** (Port 6379): In-memory cache
- **RabbitMQ** (Port 5672): Message broker

## 🔐 Security Architecture

### Security Group Rules

#### Frontend Tier
```
Inbound:
- Port 22: Bastion host CIDR only
- Port 80: From ALB security group
- Port 443: From ALB security group

Outbound:
- All traffic: 0.0.0.0/0
```

#### Application Tier
```
Inbound:
- Port 22: Bastion host CIDR only
- Port 8080: From web subnets and app subnets

Outbound:
- All traffic: 0.0.0.0/0
```

#### Database Tier
```
Inbound:
- Port 22: Bastion host CIDR only
- Service Port: From app subnets only

Outbound:
- All traffic: 0.0.0.0/0
```

#### Load Balancer Security Groups
```
Public ALB:
- Port 80/443: From 0.0.0.0/0

Internal ALB:
- Port 80/443: From web and app subnets
```

## 🚀 Deployment Automation

### User Data Script Flow

Each instance runs the following during startup:
1. Install Python 3.11 and pip
2. Install Ansible and HashiCorp Vault client
3. Execute ansible-pull to configure the service
4. Pull configuration from GitHub repository
5. Apply environment-specific configurations

### Ansible Integration

The user data script executes:
```bash
ansible-pull -i localhost, \
  -U https://github.com/prashanthkp3103/roboshop-latest-ansible \
  main.yml \
  -e env=${env} \
  -e role_name=${role_name} \
  -e vault_token=${vault_token}
```

## 📊 Auto Scaling Strategy

### Scaling Triggers
- **CPU Utilization**: Scale out at >70%, scale in at <30%
- **Request Count**: Scale based on ALB request count
- **Custom Metrics**: Application-specific metrics

### Health Checks
- **ALB Health Check**: HTTP endpoint checks
- **EC2 Health Check**: Instance-level health
- **ELB Health Check**: Load balancer health
- **Auto Recovery**: Automatic unhealthy instance replacement

## 🌐 DNS and Load Balancing

### Route53 Integration
- Each service gets a DNS record: `{service-name}-{env}.{domain}`
- Internal services use private hosted zone
- External services use public hosted zone

### Load Balancer Configuration
- **Algorithm**: Round robin (default)
- **Health Check**: HTTP GET on service endpoint
- **Deregistration Delay**: 30 seconds
- **Connection Draining**: Graceful connection termination

## 🔄 State Management

### Remote State Backend
```hcl
terraform {
  backend "s3" {
    bucket = "d80-terraform-ppk"
    key    = "roboshop-tf/{env}/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### State Locking
- DynamoDB table for state locking (if configured)
- Prevents concurrent state modifications
- Ensures infrastructure consistency

## 🔧 Extensibility Patterns

### Adding New Microservices
1. Add entry to `apps` map in tfvars
2. Define network placement (`subnet_ref`)
3. Configure security (`allow_sg_cidr`)
4. Set scaling parameters (`capacity`)
5. Apply terraform

### Multi-Region Deployment
- Duplicate environment directories
- Update AZ and region configurations
- Configure cross-region networking if needed

### Blue-Green Deployments
- Use separate ASGs for blue/green
- Update ALB target groups for traffic switching
- Maintain parallel environments

## 📈 Monitoring and Alerting

### CloudWatch Metrics
- **ASG Metrics**: Instance count, health
- **ALB Metrics**: Request count, latency, errors
- **EC2 Metrics**: CPU, memory, disk, network

### Recommended Alarms
- High CPU utilization (>80%)
- ALB 5xx error rate (>5%)
- Instance failure rate (>10%)
- Response time (>2 seconds)

## 🛡️ Security Best Practices

### Network Security
- Private subnets for databases
- Security group restrictions
- No direct internet access for internal services
- VPC flow logs for monitoring

### Access Security
- Bastion host as single entry point
- Key-based SSH authentication
- Regular security group audits
- Least privilege access

### Data Security
- Encryption at rest (EBS volumes)
- Encryption in transit (SSL/TLS)
- Secrets management with Vault
- Regular security updates

## 🔍 Troubleshooting Guide

### Common Issues

1. **Instance Launch Failures**
   - Check AMI availability in region
   - Verify instance type availability
   - Review security group rules

2. **ALB Health Check Failures**
   - Verify application is listening on correct port
   - Check security group allows ALB access
   - Review health check path and response

3. **Scaling Issues**
   - Check CloudWatch metrics
   - Verify scaling policies
   - Review service limits

4. **Network Connectivity**
   - Verify route table configurations
   - Check NACLs (if configured)
   - Review security group rules

### Debugging Commands
```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=*-dev"

# View ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name>
```

This architecture provides a robust, scalable, and secure foundation for the RoboShop e-commerce platform.