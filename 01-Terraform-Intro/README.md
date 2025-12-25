# Introduction to Terraform

A comprehensive guide to understanding Infrastructure as Code and Terraform fundamentals.

---

## What is Infrastructure as Code (IaC)?

Traditional manual setup in cloud platforms (like creating VPCs, subnets, or S3 buckets) is often repetitive, error-prone, and difficult to maintain. Infrastructure as Code solves this by treating infrastructure configuration as code—like a blueprint for a building—enabling you to recreate identical setups consistently.

### Benefits of IaC

- **Consistency:** Development, staging, and production environments are built identically
- **Time Savings:** Eliminate repetitive manual configuration tasks
- **Reduced Errors:** Clear definitions minimize human mistakes
- **Environment Parity:** Solves the "works on my machine" problem
- **Scalability:** Deploying 1 or 100 resources requires similar effort
- **Version Control:** Track infrastructure changes over time
- **Documentation:** Your code serves as living documentation
- **Collaboration:** Teams can review and collaborate on infrastructure changes

### Challenges IaC Solves

- **Time:** Manual provisioning is slow and tedious
- **People:** Reduces dependency on specific individuals' knowledge
- **Cost:** Prevents resource sprawl and enables easy cleanup
- **Repetition:** Automates repetitive tasks across environments
- **Human Errors:** Eliminates configuration drift and manual mistakes
- **Security:** Enforces security policies consistently
- **Environment Issues:** "It works on my machine" becomes obsolete

---

## Infrastructure as Code Tools

| Tool | Cloud Support | Language | Notes |
|------|--------------|----------|-------|
| **Terraform** | Universal | HCL | Most popular, multi-cloud |
| **Pulumi** | Universal | Python, TypeScript, Go, C# | Programming language-based |
| **AWS CloudFormation** | AWS Only | JSON/YAML | Native AWS solution |
| **AWS CDK** | AWS Only | Python, TypeScript, Java, C# | Define infra with programming languages |
| **Azure ARM Templates** | Azure Only | JSON | Native Azure solution |
| **Azure Bicep** | Azure Only | Bicep DSL | Simpler ARM alternative |
| **Google Cloud Deployment Manager** | GCP Only | YAML/Python/Jinja2 | Native GCP solution |

---

## Why Terraform?

Terraform has become the industry standard for Infrastructure as Code due to its unique advantages:

### Key Features

- **Multi-Cloud Support:** Manage AWS, Azure, GCP, and 3000+ providers with one tool
- **Declarative Syntax:** Describe the desired state, Terraform figures out how to achieve it
- **State Management:** Tracks current infrastructure state for intelligent updates
- **Dependency Graph:** Automatically determines resource creation order
- **Immutable Infrastructure:** Promotes replacing rather than modifying resources
- **Large Ecosystem:** Thousands of modules and providers available
- **Plan Before Apply:** Preview changes before executing them
- **Resource Graph Visualization:** Understand infrastructure dependencies

### Benefits in Practice

- Write configuration once, reuse across environments
- Track all changes in version control (Git)
- Enable peer review through pull requests
- Safely update infrastructure with predictable changes
- Destroy temporary environments easily to control costs
- Maintain a single source of truth for your infrastructure

---

## How Terraform Works

### Architecture

```
┌─────────────────┐
│  .tf Files      │  ← You write these (HCL)
│  (Config)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Terraform CLI  │  ← Processes your config
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Providers      │  ← AWS, Azure, GCP plugins
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Cloud APIs     │  ← Actual infrastructure
└─────────────────┘
```

### Core Concepts

#### 1. Providers
Providers are plugins that enable Terraform to interact with cloud platforms, SaaS services, and APIs.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

#### 2. Resources
Resources are the infrastructure components you want to create (EC2 instances, S3 buckets, etc.).

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-terraform-bucket"

  tags = {
    Name        = "My Bucket"
    Environment = "Development"
  }
}
```

#### 3. Data Sources
Data sources allow you to fetch information about existing resources.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

#### 4. Variables
Variables make your configuration reusable and flexible.

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}
```

#### 5. Outputs
Outputs expose values after resources are created.

```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.example.id
}
```

#### 6. State
Terraform maintains a state file (`terraform.tfstate`) that maps your configuration to real-world resources. This file is critical for:
- Tracking resource metadata
- Improving performance
- Determining what changes to make

**Important:** Never manually edit the state file. Use remote state (S3, Terraform Cloud) for team collaboration.

---

## Terraform Workflow

### Standard Development Cycle

```bash
# 1. Initialize the working directory
terraform init
# Downloads providers and prepares the backend

# 2. Validate configuration syntax
terraform validate
# Checks for syntax errors in .tf files

# 3. Format code consistently
terraform fmt
# Automatically formats your configuration files

# 4. Preview changes
terraform plan
# Shows what will be created, modified, or destroyed

# 5. Apply changes
terraform apply
# Creates or updates infrastructure (asks for confirmation)

# 6. View current state
terraform show
# Displays the current state or plan

# 7. Destroy infrastructure
terraform destroy
# Removes all resources defined in your config
```

### Additional Useful Commands

```bash
# Apply without confirmation prompt
terraform apply -auto-approve

# Target specific resources
terraform apply -target=aws_s3_bucket.example

# View outputs
terraform output

# List resources in state
terraform state list

# View detailed resource state
terraform state show aws_s3_bucket.example

# Import existing resources
terraform import aws_s3_bucket.example my-bucket-name

# Create an execution plan file
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Installing Terraform

### macOS

```bash
# Using Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform -version
```

### Ubuntu/Debian

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt update && sudo apt install terraform

# Verify installation
terraform -version
```

### CentOS/RHEL

```bash
# Add HashiCorp repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# Verify installation
terraform -version
```

### Windows

**Option 1: Manual Installation**

1. Visit `https://terraform.io/downloads`
2. Click on Windows and download the ZIP file
3. Extract the folder and copy `terraform.exe`
4. Create folder: `C:\Program Files\Terraform`
5. Paste `terraform.exe` into this folder
6. Add to PATH:
   - Open "Environment Variables" in Windows
   - Click "Environment Variables"
   - Select "Path" under "System variables" → Click "Edit"
   - Click "New" → Paste the Terraform folder path (`C:\Program Files\Terraform`)
   - Click "OK" to save

**Option 2: Using Chocolatey**

```powershell
choco install terraform
```

**Verify Installation:**

```bash
terraform -version
```

### VS Code Extension

For better development experience:

1. Open VS Code
2. Click on Extensions (or press `Ctrl+Shift+X`)
3. Search for `HashiCorp Terraform`
4. Install the official HashiCorp extension

**Features:**
- Syntax highlighting
- Auto-completion
- Code formatting
- Linting and validation
- Snippets for common patterns

---

## Project Structure

A well-organized Terraform project typically follows this structure:

```
terraform-project/
├── main.tf              # Main configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── terraform.tfvars     # Variable values (don't commit secrets!)
├── providers.tf         # Provider configurations
├── versions.tf          # Terraform and provider versions
├── backend.tf           # Remote state configuration
├── .gitignore           # Ignore state files and secrets
│
├── modules/             # Reusable modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/        # Environment-specific configs
    ├── dev/
    │   ├── main.tf
    │   └── terraform.tfvars
    ├── staging/
    └── production/
```

---

## Complete Example: AWS EC2 Instance

### main.tf

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
  region = var.aws_region
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

### variables.tf

```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-demo"
}
```

### outputs.tf

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.web_server.instance_state
}
```

### terraform.tfvars

```hcl
aws_region    = "us-west-2"
instance_type = "t3.micro"
environment   = "production"
project_name  = "my-app"
```

---

## Best Practices

### 1. Version Control

```gitignore
# .gitignore
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
*.tfvars.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc
```

### 2. Remote State

Always use remote state for team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 3. Use Modules

Break complex configurations into reusable modules:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

### 4. Variable Validation

Add validation rules to catch errors early:

```hcl
variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 5. Use Workspaces

Manage multiple environments:

```bash
# Create and switch to workspace
terraform workspace new dev
terraform workspace new prod

# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select dev
```

### 6. Tag Everything

Apply consistent tagging for resource management:

```hcl
locals {
  common_tags = {
    Project     = "MyApp"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}

resource "aws_instance" "example" {
  # ... other configuration ...

  tags = merge(
    local.common_tags,
    {
      Name = "web-server"
    }
  )
}
```

### 7. Security Practices

- Never commit secrets or credentials
- Use environment variables or secret management tools
- Enable encryption for state files
- Use IAM roles instead of access keys when possible
- Implement least privilege access

```bash
# Use environment variables for AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

---

## Common Pitfalls and Solutions

### 1. State File Conflicts

**Problem:** Multiple people applying changes simultaneously.

**Solution:** Use remote state with state locking (DynamoDB for S3 backend).

### 2. Hard-Coded Values

**Problem:** Region or environment-specific values hard-coded.

**Solution:** Use variables and terraform.tfvars files.

### 3. Not Using Version Constraints

**Problem:** Provider versions change, breaking your code.

**Solution:** Always specify version constraints.

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allows 5.x but not 6.0
    }
  }
}
```

### 4. Large State Files

**Problem:** State file becomes too large and slow.

**Solution:** Split infrastructure into separate state files or use workspaces.