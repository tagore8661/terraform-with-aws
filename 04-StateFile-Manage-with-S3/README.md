# Terraform State File Management with AWS S3 Backend

## Table of Contents
1. [What is Terraform State?](#what-is-terraform-state)
2. [Why State Management Matters](#why-state-management-matters)
3. [Local State vs Remote State](#local-state-vs-remote-state)
4. [Introduction to S3 Backend](#introduction-to-s3-backend)
5. [Setting Up S3 Backend](#setting-up-s3-backend)
6. [How It Works](#how-it-works)
7. [Advantages](#advantages)
8. [Disadvantages](#disadvantages)
9. [Best Practices](#best-practices)
10. [Common Issues & Solutions](#common-issues--solutions)
11. [Security Considerations](#security-considerations)
12. [Real-World Example](#real-world-example)

---

## What is Terraform State?

Think of Terraform state as a **detailed inventory list** of all your cloud resources. When you use Terraform to create infrastructure (like servers, databases, networks), it writes down everything it creates in a special file called `terraform.tfstate`.

### What's Inside the State File?

```
- Resource IDs (unique identifiers)
- Resource attributes (IP addresses, names, configurations)
- Dependencies (which resources depend on others)
- Metadata (timestamps, versions)
- Sensitive data (passwords, keys) ⚠️
```

### Example Scenario

Imagine you're managing a house:
- **Your Blueprint (Terraform Code)**: Plans showing what rooms you want
- **The Actual House (Real Infrastructure)**: What physically exists
- **The Inventory List (State File)**: A record of every room, door, and window that's been built

When you want to add a new room, Terraform checks the inventory list to see what already exists, then only builds what's missing.

---

## Why State Management Matters

### The Problem Terraform Solves

Without a state file, Terraform would have to:
1. Check every single resource in your cloud account (slow)
2. Try to figure out what it created vs what existed before (error-prone)
3. Potentially duplicate resources (expensive)

### What State Enables

- **Faster Operations**: Terraform knows what exists without checking everything
- **Accurate Updates**: Only changes what needs changing
- **Resource Tracking**: Maps your code to real infrastructure
- **Dependency Management**: Understands relationships between resources
- **Collaboration**: Multiple team members can work together

---

## Local State vs Remote State

### Local State (Default Behavior)

When you first run Terraform, it stores the state file on your computer.

**Location**: `./terraform.tfstate` in your project folder

#### Problems with Local State

| Problem | Impact | Example |
|---------|--------|---------|
| **Single Point of Failure** | If your laptop crashes, you lose track of all infrastructure | Your hard drive fails → state file gone → can't manage resources |
| **No Team Collaboration** | Only one person can work at a time | Two developers run `apply` simultaneously → conflicting changes |
| **Security Risk** | Sensitive data stored on your machine | State file contains database passwords in plain text |
| **No Backup** | Accidental deletion means data loss | You run `rm -rf *` in wrong folder → state deleted |
| **Version Control Issues** | Should NOT commit to Git (contains secrets) | State file in Git → passwords exposed in repository history |

### Remote State (Recommended Solution)

Store the state file in a centralized, secure location that everyone can access.

**Popular Options**:
- AWS S3 (most common)
- Terraform Cloud
- Azure Blob Storage
- Google Cloud Storage
- HashiCorp Consul

---

## Introduction to S3 Backend

### What is an S3 Backend?

S3 Backend means storing your Terraform state file in an **AWS S3 bucket** instead of your local computer.

### Why S3?

- **Secure**: Supports encryption at rest and in transit
- **Accessible**: Team members can access from anywhere
- **Reliable**: 99.999999999% durability (Amazon's guarantee)
- **Cost-Effective**: Pennies per month for storage
- **State Locking**: Works with DynamoDB to prevent conflicts
- **Versioning**: Keep history of all state changes

### How It Works (Simple Explanation)

```
Your Computer                    AWS Cloud
─────────────                    ─────────

terraform apply
      │
      ├──→ Downloads current state from S3
      │
      ├──→ Makes infrastructure changes
      │
      └──→ Uploads updated state back to S3

Next team member:
terraform plan
      │
      └──→ Downloads latest state from S3 (includes your changes)
```

---

## Setting Up S3 Backend

### Prerequisites

Before you start, you need:
-  AWS Account with appropriate permissions
-  AWS CLI configured (`aws configure`)
-  Terraform installed (`terraform --version`)
-  S3 bucket created (we'll do this first)
-  (Optional) DynamoDB table for state locking

### Step 1: Create S3 Bucket

You can create the bucket manually or use Terraform:

**Option A: Using AWS CLI**
```bash
aws s3 mb s3://my-terraform-state-bucket-unique-name --region us-east-1
```

**Option B: Using Terraform (Bootstrap)**
```hcl
# bootstrap.tf
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket-unique-name"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Step 2: (Optional) Create DynamoDB Table for Locking

```hcl
# bootstrap.tf
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Step 3: Configure Backend in Your Main Configuration

Create or update your `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"

  # Backend configuration
  backend "s3" {
    bucket         = "my-terraform-state-bucket-unique-name"
    key            = "path/to/my/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### Step 4: Initialize Backend

```bash
# Initialize Terraform with the new backend
terraform init

# If migrating from local state, Terraform will ask:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### Step 5: Verify Setup

```bash
# Check if state is now remote
ls -la terraform.tfstate
# You should see a small file (just metadata)

# Check S3 bucket
aws s3 ls s3://my-terraform-state-bucket-unique-name/path/to/my/
# You should see terraform.tfstate
```

---

## How It Works

### Backend Configuration Options Explained

```hcl
backend "s3" {
  bucket         = "my-state-bucket"        # S3 bucket name
  key            = "env/prod/terraform.tfstate"  # Path inside bucket
  region         = "us-east-1"              # AWS region
  encrypt        = true                     # Enable encryption
  dynamodb_table = "terraform-locks"        # Table for state locking

  # Advanced options
  acl            = "private"                # Access control
  kms_key_id     = "arn:aws:kms:..."        # Custom encryption key
  workspace_key_prefix = "workspaces"       # Workspace organization
}
```

### State File Organization

**Recommended Structure**:
```
s3://my-state-bucket/
├── production/
│   ├── networking/terraform.tfstate
│   ├── compute/terraform.tfstate
│   └── database/terraform.tfstate
├── staging/
│   ├── networking/terraform.tfstate
│   └── compute/terraform.tfstate
└── development/
    └── all/terraform.tfstate
```

### Workflow with Remote State

1. **Developer A** runs `terraform apply`
   - Terraform acquires lock in DynamoDB
   - Downloads state from S3
   - Makes changes to infrastructure
   - Updates state file
   - Uploads state to S3
   - Releases lock

2. **Developer B** runs `terraform plan` (while A is working)
   - Terraform tries to acquire lock
   - Lock is held by Developer A
   - Waits or fails with error
   - Prevents conflicting changes

3. **After Developer A finishes**
   - Developer B can now proceed
   - Gets latest state with A's changes
   - No conflicts

---

## Advantages

### 1. **Team Collaboration**
Multiple people can work on the same infrastructure without stepping on each other's toes.

**Example**: Developer A adds a server while Developer B adds a database. Both changes are coordinated through the shared state.

### 2. **Centralized & Secure Storage**
State file is in a professional-grade storage system, not scattered across laptops.

**Benefit**: No more "works on my machine" problems.

### 3. **Automatic Backups**
S3 versioning keeps history of every state change.

**Recovery**: Made a mistake? Restore previous version:
```bash
aws s3api list-object-versions --bucket my-state-bucket --prefix prod/
aws s3api get-object --bucket my-state-bucket --key prod/terraform.tfstate --version-id [VERSION_ID] old-state.tfstate
```

### 4. **State Locking**
Prevents simultaneous modifications that could corrupt infrastructure.

**Analogy**: Like a bathroom door lock - only one person can make changes at a time.

### 5. **Encryption**
Protects sensitive data (passwords, keys) stored in the state file.

**Options**:
- Server-side encryption (S3 default)
- KMS encryption (your own keys)
- SSL/TLS for data in transit

### 6. **Access Control**
Use AWS IAM to control who can read/write state files.

**Example**:
- Developers: Read-only access
- CI/CD Pipeline: Read-write access
- Admins: Full access

### 7. **Disaster Recovery**
State file survives laptop crashes, accidental deletions, or office fires.

**S3 Durability**: Designed to sustain the loss of data in 2 facilities.

### 8. **Audit Trail**
S3 logging tracks who accessed or modified the state file.

**Use Case**: Find out who made that infrastructure change last Thursday.

### 9. **Cost Effective**
Storing state files costs almost nothing.

**Example Cost**: 100 state files (10MB each) = ~$0.02/month

### 10. **CI/CD Integration**
Automated pipelines can safely run Terraform without manual intervention.

**Example**: GitLab CI/CD automatically applies changes after code review.

---

## Disadvantages

### 1. **Initial Setup Complexity**
Requires creating S3 bucket and possibly DynamoDB table first.

**Mitigation**: Use bootstrap scripts or manual setup once.

### 2. **Bootstrap Problem**
Can't use Terraform to manage the S3 bucket that stores Terraform state (chicken and egg).

**Solution**:
- Create S3 bucket manually first, OR
- Use separate Terraform project for backend resources

### 3. **Network Dependency**
Need internet connection to AWS to run Terraform commands.

**Impact**: Can't work completely offline.

### 4. **AWS Costs**
Small ongoing costs for S3 storage and DynamoDB (if used).

**Reality**: Usually under $1/month, negligible for most projects.

### 5. **Credential Management**
Team members need AWS credentials configured properly.

**Challenge**: More setup for new team members.

### 6. **Lock Management**
If Terraform crashes, lock might not release automatically.

**Fix**:
```bash
# Manual lock removal (use carefully)
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"my-state-bucket/prod/terraform.tfstate"}}'
```

### 7. **State File Size**
Large infrastructures = large state files = slower operations.

**Mitigation**: Split infrastructure into multiple state files.

### 8. **AWS Region Dependency**
If AWS region has an outage, can't access state.

**Mitigation**:
- Use stable regions
- S3 cross-region replication
- Local state backup

### 9. **Learning Curve**
New team members need to understand remote state concepts.

**Solution**: Good documentation (like this README).

### 10. **Potential Lock Contention**
Multiple teams might wait for locks during busy periods.

**Solution**: Split into multiple state files per team/component.

---

## Best Practices

### 1. **Enable Versioning**
Always turn on S3 versioning for state files.

```hcl
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 2. **Use Encryption**
Protect sensitive data in state files.

```hcl
backend "s3" {
  encrypt    = true
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}
```

### 3. **Implement State Locking**
Always use DynamoDB table for locking.

```hcl
backend "s3" {
  dynamodb_table = "terraform-state-locks"
}
```

### 4. **Separate Environments**
Use different state files for dev, staging, production.

```
s3://state-bucket/dev/terraform.tfstate
s3://state-bucket/staging/terraform.tfstate
s3://state-bucket/prod/terraform.tfstate
```

### 5. **Block Public Access**
Never allow public access to state buckets.

```hcl
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 6. **Use IAM Roles**
Implement least-privilege access control.

```hcl
# Read-only for developers
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::my-state-bucket",
    "arn:aws:s3:::my-state-bucket/*"
  ]
}
```

### 7. **Enable Logging**
Track who accesses state files.

```hcl
resource "aws_s3_bucket_logging" "state" {
  bucket = aws_s3_bucket.state.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "state-access-logs/"
}
```

### 8. **Regular Backups**
Periodically download state files as backup.

```bash
# Backup script
aws s3 cp s3://my-state-bucket/prod/terraform.tfstate \
  ./backups/terraform.tfstate.$(date +%Y%m%d)
```

### 9. **Use Workspaces Carefully**
Consider separate state files instead of workspaces for environments.

**Why**: Workspaces share the same backend configuration, increasing risk.

### 10. **Document Backend Configuration**
Keep clear documentation for team members.

```markdown
# Backend Setup
- Bucket: my-terraform-state
- Region: us-east-1
- Lock Table: terraform-locks
- Access: Request from DevOps team
```

### 11. **Never Manually Edit State**
Always use Terraform commands to modify state.

```bash
# Good ways to modify state
terraform state rm aws_instance.example
terraform state mv aws_instance.old aws_instance.new
terraform import aws_instance.new i-1234567890abcdef0

# Bad
vim terraform.tfstate  #  NEVER DO THIS
```

### 12. **Test State Operations**
Verify state operations in development first.

```bash
# Test in dev environment
terraform plan
terraform apply

# Then promote to production
```

---

## Common Issues & Solutions

### Issue 1: "Error Acquiring State Lock"

**Problem**: Another process is using the state or lock wasn't released.

```
Error: Error acquiring the state lock
Lock Info:
  ID: 12345678-1234-1234-1234-123456789012
  Path: my-bucket/terraform.tfstate
  Operation: OperationTypeApply
  Who: user@hostname
```

**Solutions**:

```bash
# Option 1: Wait for the other process to finish

# Option 2: Force unlock (dangerous - ensure no one else is running Terraform)
terraform force-unlock 12345678-1234-1234-1234-123456789012

# Option 3: Remove lock from DynamoDB
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"my-bucket/terraform.tfstate"}}'
```

### Issue 2: "Backend Configuration Changed"

**Problem**: Backend settings were modified.

```
Error: Backend configuration changed
```

**Solution**:

```bash
# Reinitialize with new configuration
terraform init -reconfigure

# Or migrate state
terraform init -migrate-state
```

### Issue 3: "Failed to Load State"

**Problem**: State file is corrupted or inaccessible.

**Solutions**:

```bash
# Check S3 access
aws s3 ls s3://my-state-bucket/

# Restore from backup
aws s3api list-object-versions --bucket my-state-bucket --prefix terraform.tfstate

# Get specific version
aws s3api get-object \
  --bucket my-state-bucket \
  --key terraform.tfstate \
  --version-id [VERSION_ID] \
  recovered-state.tfstate
```

### Issue 4: "Backend Initialization Required"

**Problem**: Working directory not initialized.

```
Error: Backend initialization required
```

**Solution**:

```bash
terraform init
```

### Issue 5: State Drift

**Problem**: Real infrastructure doesn't match state file.

**Detection**:

```bash
terraform plan
# Shows resources that will be modified/destroyed
```

**Solutions**:

```bash
# Option 1: Refresh state to match reality
terraform apply -refresh-only

# Option 2: Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Option 3: Remove from state if resource was deleted manually
terraform state rm aws_instance.deleted_resource
```

### Issue 6: Large State File Performance

**Problem**: Terraform operations are slow.

**Solutions**:

1. **Split Infrastructure**: Break into smaller modules with separate state files
2. **Use Targeted Operations**:
   ```bash
   terraform plan -target=aws_instance.specific_resource
   ```
3. **Optimize Provider Configuration**: Reduce unnecessary data sources

### Issue 7: Access Denied Errors

**Problem**: Insufficient AWS permissions.

```
Error: error reading S3 Bucket: AccessDenied
```

**Solution**: Verify IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::my-state-bucket"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-state-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-locks"
    }
  ]
}
```

---

## Security Considerations

### 1. **Sensitive Data in State**

State files contain sensitive information:
- Database passwords
- API keys
- Private keys
- Connection strings

**Protection Methods**:
- Enable S3 encryption (server-side)
- Use KMS for encryption keys
- Restrict IAM access
- Enable S3 bucket versioning
- Never commit state to Git

### 2. **Access Control**

Implement role-based access:

```hcl
# Strict IAM policy
resource "aws_iam_policy" "terraform_state_access" {
  name        = "TerraformStateAccess"
  description = "Policy for Terraform state access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}/*/terraform.tfstate"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}
```

### 3. **Encryption at Rest**

**Server-Side Encryption (SSE-S3)**:
```hcl
backend "s3" {
  encrypt = true  # Uses AWS-managed keys
}
```

**KMS Encryption (SSE-KMS)**:
```hcl
backend "s3" {
  encrypt    = true
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}
```

### 4. **Encryption in Transit**

Always use HTTPS:
```hcl
backend "s3" {
  endpoint = "https://s3.amazonaws.com"  # Enforces HTTPS
}
```

### 5. **Audit Logging**

Enable CloudTrail and S3 access logging:

```hcl
resource "aws_s3_bucket_logging" "state_logging" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "state-access/"
}
```

### 6. **MFA Delete**

Require multi-factor authentication for state deletion:

```bash
aws s3api put-bucket-versioning \
  --bucket my-state-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::123456789012:mfa/user 123456"
```

### 7. **Network Security**

Use VPC endpoints for private connectivity:

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
}
```

---

## Real-World Example

Let's walk through a complete, production-ready setup.

### Scenario

Company "Tag" wants to manage AWS infrastructure for:
- Development environment
- Staging environment
- Production environment

### Step 1: Create Bootstrap Configuration

**File: `bootstrap/main.tf`**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Purpose   = "StateManagement"
    }
  }
}

# S3 Bucket for state files
resource "aws_s3_bucket" "terraform_state" {
  bucket = "tag-terraform-state-2025"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Global"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "tag-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Global"
  }
}

# Outputs for reference
output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket for Terraform state"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.id
  description = "Name of the DynamoDB table for state locking"
}
```

### Step 2: Initialize Bootstrap

```bash
cd bootstrap/
terraform init
terraform plan
terraform apply

# Save outputs
terraform output
```

### Step 3: Create Production Infrastructure

**File: `production/main.tf`**

```hcl
terraform {
  required_version = ">= 1.0"

  # Remote backend configuration
  backend "s3" {
    bucket         = "tag-terraform-state-2025"
    key            = "production/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tag-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "production-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "production-public-subnet"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "production-web-server"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
```

### Step 4: Initialize and Deploy

```bash
cd production/
terraform init

# Initialize backend and migrate any existing state
# Terraform will prompt: "Do you want to copy existing state to the new backend?"
# Answer: yes

terraform plan
terraform apply

# Verify state is in S3
aws s3 ls s3://tag-terraform-state-2025/production/infrastructure/
```

### Step 5: Team Member Setup

**Documentation for new team members**:

```markdown
# tag Terraform Setup

## Prerequisites
1. Install Terraform 1.0+
2. Configure AWS CLI with your credentials
3. Get IAM permissions from DevOps team

## Quick Start

# Clone repository
git clone https://github.com/tag/infrastructure.git
cd infrastructure/production

# Initialize Terraform (will download state from S3)
terraform init

# View current infrastructure
terraform plan

# Apply changes (after code review)
terraform apply
```

### Step 6: CI/CD Integration

**File: `.github/workflows/terraform.yml`**

```yaml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        run: terraform init
        working-directory: ./production

      - name: Terraform Format
        run: terraform fmt -check
        working-directory: ./production

      - name: Terraform Plan
        run: terraform plan
        working-directory: ./production

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
        working-directory: ./production
```
