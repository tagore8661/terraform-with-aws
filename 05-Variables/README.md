# Terraform Variables in AWS


## Table of Contents

0. [What is a Variable?](#what-is-a-variable) - Overview and introduction
2. [Input Variables](#1-input-variables) - Parameterize your configurations
3. [Local Variables](#2-local-variables) - Compute and reuse values internally
4. [Output Variables](#3-output-variables) - Expose information after creation
5. [Variable Types](#4-variable-types) - Understand data types
6. [Variable Definition Files](#5-variable-definition-files) - Organize configurations
7. [Variable Precedence](#6-variable-precedence) - Understand priority order
8. [Environment Variables](#7-environment-variables) - Set values from shell
9. [Variable Validation](#8-variable-validation) - Enforce constraints
10. [Sensitive Variables](#9-sensitive-variables) - Protect confidential data
11. [Best Practices](#10-best-practices) - Write maintainable code
12. [Common Patterns](#11-common-patterns) - Real-world usage examples
13. [AWS-Specific Examples](#12-aws-specific-examples) - Practical implementations

---

## What is a Variable?

### Simple Definition

A **variable** in Terraform is a placeholder for a value that you can pass into your configuration. Instead of hardcoding values directly in your infrastructure code, variables let you define values once and reuse them throughout your configuration. This makes your code more flexible, maintainable, and reusable across different environments.

### Key Characteristics

- **Parameterization**: Variables act like function parameters that allow you to customize behavior without changing code
- **Reusability**: Define a value once and use it in multiple places
- **Environment-specific**: Different environments (dev, staging, prod) can use different values
- **Version Control Friendly**: Keep sensitive data separate from code
- **Maintainability**: Update configuration in one place instead of many

### Real-World Example

Instead of this (hardcoded):
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  region        = "us-east-1"
}
```

You write this (with variables):
```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  region        = var.aws_region
}
```

Then provide values separately, making it reusable for any environment.

---

## 1. Input Variables

### Overview
Input variables are the first type of variable you should understand in Terraform. They are the primary way to parameterize your infrastructure code and are the foundation for reusable configurations.

Input variables let you customize your Terraform configuration without altering the source code. They act as parameters for your Terraform modules.

### Basic Syntax

```hcl
variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

### Key Benefits

- Define a value once and use it across multiple resources
- Avoid repetitive typing and reduce mistakes
- Change the value in one place to update all references
- Make configurations reusable across different environments
- Enable collaboration by separating configuration from code

### Variable Block Components

```hcl
variable "instance_type" {
  description = "EC2 instance type"           # Human-readable description
  type        = string                        # Data type
  default     = "t2.micro"                    # Default value if not provided
  sensitive   = false                         # Hide value in logs
  nullable    = true                          # Allow null values

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}
```

### Using Input Variables

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = var.environment == "prod" ? "t2.large" : var.instance_type

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}
```

### Variable Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `type` | No | Specifies the data type (string, number, bool, list, map, set, object, tuple, any) |
| `default` | No | Default value if not provided |
| `description` | No | Documentation for the variable |
| `validation` | No | Custom validation rules |
| `sensitive` | No | Marks variable as sensitive (hides in output) |
| `nullable` | No | Whether null is a valid value (default: true) |

---

## 2. Local Variables

### Overview
Once you understand input variables, local variables come next. They help you compute and transform values internally within your configuration, reducing code repetition.

Local variables are internal helper variables within your Terraform configuration. They are computed values that help reduce repetition and improve readability.

### Basic Syntax

```hcl
locals {
  bucket_name = "tagore8661-${var.environment}"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}
```

### Key Benefits

- Combine or transform input variables
- Reduce repetition in configuration
- Make complex expressions reusable
- Improve code readability and maintainability
- Can reference other local values

### Using Local Variables

```hcl
resource "aws_s3_bucket" "data" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  tags          = merge(local.common_tags, {
    Name = "${var.project_name}-web-server"
  })
}
```

### Complex Local Values

```hcl
locals {
  # String interpolation
  db_name = "${var.project_name}_${var.environment}_db"

  # Conditional logic
  instance_count = var.environment == "prod" ? 3 : 1

  # List manipulation
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # Map transformation
  subnet_ids = {
    for idx, subnet in aws_subnet.private :
    idx => subnet.id
  }

  # Multiple values in one block
  network_config = {
    vpc_cidr    = "10.0.0.0/16"
    subnet_cidr = "10.0.1.0/24"
    enable_dns  = true
  }
}
```

### Locals vs Variables

| Feature | Input Variables | Local Variables |
|---------|----------------|-----------------|
| Set from outside | Yes | No |
| Can have default | Yes | Must be defined |
| Can be overridden | Yes | No |
| Use case | External configuration | Internal computation |

---

## 3. Output Variables

### Overview
After resources are created, output variables allow you to display and expose important information. They help you extract and communicate critical values generated by Terraform.

Output variables display values after Terraform creates resources. They expose information from your infrastructure that you might need later.

### Basic Syntax

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}
```

### Key Benefits

- Show key values generated after resource creation
- Pass data between modules
- Display important information to users
- Can be queried using `terraform output` command
- Enable automation by exposing resource attributes

### Output Block Components

```hcl
output "instance_details" {
  description = "EC2 instance information"
  value       = {
    id         = aws_instance.web.id
    public_ip  = aws_instance.web.public_ip
    private_ip = aws_instance.web.private_ip
  }
  sensitive   = false
  depends_on  = [aws_instance.web]
}
```

### Accessing Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output vpc_id

# Get output in JSON format
terraform output -json

# Use in scripts
VPC_ID=$(terraform output -raw vpc_id)
```

### Sensitive Outputs

```hcl
output "db_password" {
  description = "Database password"
  value       = aws_db_instance.main.password
  sensitive   = true  # Won't show in console
}
```

### Output Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `value` | Yes | The value to output |
| `description` | No | Documentation for the output |
| `sensitive` | No | Hide value in CLI output |
| `depends_on` | No | Explicit dependencies |
| `precondition` | No | Validation before output |

### Using Outputs Between Modules

```hcl
# In networking module
output "vpc_id" {
  value = aws_vpc.main.id
}

# In compute module
module "networking" {
  source = "./modules/networking"
}

resource "aws_instance" "app" {
  vpc_id = module.networking.vpc_id
}
```

---

## 4. Variable Types

### Overview
Understanding data types is crucial for writing robust Terraform code. Different types provide different capabilities and validation.

Terraform supports multiple data types for variables. Choosing the right type ensures type safety and better validation.

### Primitive Types

#### String
```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}

# Usage
region = "us-west-2"
```

#### Number
```hcl
variable "instance_count" {
  type    = number
  default = 3
}

# Usage
instance_count = 5
```

#### Bool
```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}

# Usage
enable_monitoring = false
```

### Collection Types

#### List
Ordered sequence of values of the same type.

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Usage
availability_zones = ["us-west-2a", "us-west-2b"]

# Access
resource "aws_subnet" "main" {
  count             = length(var.availability_zones)
  availability_zone = var.availability_zones[count.index]
}
```

#### Set
Unordered collection of unique values.

```hcl
variable "security_group_ids" {
  type    = set(string)
  default = []
}

# Usage
security_group_ids = ["sg-12345", "sg-67890"]
```

#### Map
Collection of key-value pairs.

```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Usage
tags = {
  Environment = "prod"
  Team        = "DevOps"
}

# Access
resource "aws_instance" "web" {
  tags = var.tags
}
```

### Structural Types

#### Object
Collection of named attributes with their own types.

```hcl
variable "vpc_config" {
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
    tags                 = map(string)
  })

  default = {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = {
      Name = "main-vpc"
    }
  }
}

# Usage
vpc_config = {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "prod-vpc"
  }
}
```

#### Tuple
Fixed-length sequence with specific types for each element.

```hcl
variable "server_config" {
  type = tuple([string, number, bool])
  default = ["t2.micro", 1, true]
}

# Usage
server_config = ["t2.large", 3, false]
```

### Complex Type Examples

#### List of Objects
```hcl
variable "subnets" {
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
  }))

  default = [
    {
      name              = "public-1"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name              = "public-2"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  ]
}
```

#### Map of Objects
```hcl
variable "environments" {
  type = map(object({
    instance_type = string
    instance_count = number
    enable_monitoring = bool
  }))

  default = {
    dev = {
      instance_type = "t2.micro"
      instance_count = 1
      enable_monitoring = false
    }
    prod = {
      instance_type = "t2.large"
      instance_count = 3
      enable_monitoring = true
    }
  }
}
```

### Any Type
When you need maximum flexibility (use sparingly).

```hcl
variable "custom_config" {
  type = any
  default = {}
}
```

---

## 5. Variable Definition Files

### Overview
After learning types, understanding how to organize variable values across different environments is essential. Variable files allow you to maintain separate configurations for dev, staging, and production.

Variable definition files let you set values for your input variables. They help organize configurations for different environments.

### File Types

#### terraform.tfvars
The default file Terraform automatically loads.

```hcl
# terraform.tfvars
environment    = "production"
region         = "us-east-1"
instance_count = 5

tags = {
  Project   = "MyApp"
  ManagedBy = "Terraform"
}
```

#### .tfvars Files
Named variable files that must be explicitly specified.

```hcl
# production.tfvars
environment    = "prod"
instance_type  = "t2.large"
instance_count = 10
```

```bash
terraform apply -var-file="production.tfvars"
```

#### .tfvars.json Files
JSON format for variable definitions.

```json
{
  "environment": "staging",
  "region": "us-west-2",
  "instance_count": 3,
  "tags": {
    "Environment": "staging",
    "Team": "DevOps"
  }
}
```

```bash
terraform apply -var-file="staging.tfvars.json"
```

#### Auto-loaded Files
Files with these names are automatically loaded:

- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

```hcl
# dev.auto.tfvars (automatically loaded)
environment = "dev"
region      = "us-east-1"
```

### File Organization Examples

#### Single Environment
```
project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

#### Multiple Environments
```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
├── staging.tfvars
└── production.tfvars
```

#### Module Structure
```
project/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
```

### Command-Line Usage

```bash
# Use specific var file
terraform apply -var-file="prod.tfvars"

# Use multiple var files (later files override earlier ones)
terraform apply -var-file="base.tfvars" -var-file="prod.tfvars"

# Combine file and command-line variables
terraform apply -var-file="prod.tfvars" -var="instance_count=5"
```

---

## 6. Variable Precedence

### Overview
Understanding priority is crucial because Terraform can receive variable values from multiple sources. This section explains which source takes priority when values conflict.

Terraform uses a specific order to determine which value to use when multiple sources provide the same variable.

### Precedence Order (Lowest to Highest)

1. **Default value in variable block**
2. **Environment variables** (`TF_VAR_*`)
3. **terraform.tfvars** file
4. **terraform.tfvars.json** file
5. **Any *.auto.tfvars or *.auto.tfvars.json** files (alphabetical order)
6. **-var-file** command-line flag (in order specified)
7. **-var** command-line flag (in order specified)

### Precedence Examples

```hcl
# variables.tf
variable "environment" {
  default = "dev"  # Priority 1 (lowest)
}
```

```bash
# Priority 2: Environment variable
export TF_VAR_environment="staging"

# Priority 3: terraform.tfvars
# environment = "prod"

# Priority 4: Command-line var-file
terraform apply -var-file="production.tfvars"

# Priority 5: Command-line var (highest)
terraform apply -var="environment=prod"
```

### How Precedence Works

If you define:
- `default = "dev"` in variables.tf
- `export TF_VAR_environment="staging"`
- `environment = "prod"` in terraform.tfvars
- `terraform apply -var="environment=live"`

**Result**: Terraform uses `"live"` because command-line `-var` has the highest precedence.

### Best Practices for Precedence

- Use defaults for common values
- Use `.tfvars` files for environment-specific configurations
- Use environment variables for sensitive data
- Use command-line flags for temporary overrides
- Document which method your team should use

---

## 7. Environment Variables

### Overview
Environment variables offer a flexible way to pass values from your shell to Terraform. They're particularly useful in CI/CD pipelines and for managing sensitive data without committing to files.

Environment variables provide a way to set Terraform variables from your shell environment. They're useful for sensitive data or CI/CD pipelines.

### Syntax

Environment variables must be prefixed with `TF_VAR_` followed by the variable name.

```bash
# For variable "environment"
export TF_VAR_environment="production"

# For variable "instance_count"
export TF_VAR_instance_count=5

# For variable "enable_monitoring"
export TF_VAR_enable_monitoring=true
```

### Setting Environment Variables

#### Linux/MacOS
```bash
# Single session
export TF_VAR_region="us-west-2"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export TF_VAR_region="us-west-2"' >> ~/.bashrc
source ~/.bashrc
```

#### Windows (PowerShell)
```powershell
# Single session
$env:TF_VAR_region = "us-west-2"

# Permanent
[System.Environment]::SetEnvironmentVariable('TF_VAR_region', 'us-west-2', 'User')
```

#### Windows (Command Prompt)
```cmd
# Single session
set TF_VAR_region=us-west-2

# Permanent
setx TF_VAR_region "us-west-2"
```

### Complex Types in Environment Variables

Environment variables are passed as strings, so complex types need special handling.

#### List
```bash
# Use JSON format
export TF_VAR_availability_zones='["us-east-1a","us-east-1b","us-east-1c"]'
```

#### Map
```bash
export TF_VAR_tags='{"Environment":"prod","Team":"DevOps"}'
```

#### Object
```bash
export TF_VAR_vpc_config='{"cidr_block":"10.0.0.0/16","enable_dns":true}'
```

### Use Cases

#### CI/CD Pipelines
```yaml
# GitHub Actions example
jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      TF_VAR_environment: production
      TF_VAR_region: us-east-1
    steps:
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

#### Sensitive Values
```bash
# Don't commit sensitive values to version control
export TF_VAR_db_password="super-secret-password"
export TF_VAR_api_key="${API_KEY}"
```

#### Docker Containers
```bash
docker run -e TF_VAR_environment=prod \
           -e TF_VAR_region=us-east-1 \
           terraform-image
```

### Best Practices

- Use environment variables for secrets and sensitive data
- Use them in CI/CD pipelines for dynamic configurations
- Document required environment variables in README
- Never commit sensitive environment variables to version control
- Consider using secret management tools (AWS Secrets Manager, HashiCorp Vault)

---

## 8. Variable Validation

### Overview
Before applying infrastructure changes, you should validate that variable values meet your requirements. This prevents invalid configurations from being deployed.

Variable validation ensures that values meet specific criteria before Terraform applies them. This prevents errors and enforces constraints.

### Basic Syntax

```hcl
variable "instance_type" {
  type = string

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}
```

### Validation Components

| Component | Description |
|-----------|-------------|
| `condition` | Boolean expression that must be true |
| `error_message` | Message shown when validation fails |

### Common Validation Patterns

#### String Length
```hcl
variable "project_name" {
  type = string

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 20
    error_message = "Project name must be between 3 and 20 characters."
  }
}
```

#### String Format (Regex)
```hcl
variable "email" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email))
    error_message = "Email must be a valid email address."
  }
}
```

#### Number Range
```hcl
variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

#### Allowed Values
```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### IP Address Format
```hcl
variable "ip_address" {
  type = string

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "Must be a valid IP address."
  }
}
```

#### CIDR Block
```hcl
variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

### Multiple Validations

You can have multiple validation blocks for the same variable.

```hcl
variable "bucket_name" {
  type = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with lowercase letter or number."
  }

  validation {
    condition     = !can(regex("\\.\\.|\\.\\-|\\-\\.", var.bucket_name))
    error_message = "Bucket name cannot have consecutive periods or period-dash combinations."
  }
}
```

### AWS-Specific Validations

#### Region
```hcl
variable "region" {
  type = string

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-central-1",
      "ap-south-1", "ap-southeast-1", "ap-southeast-2"
    ], var.region)
    error_message = "Must be a valid AWS region."
  }
}
```

#### ARN Format
```hcl
variable "iam_role_arn" {
  type = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.iam_role_arn))
    error_message = "Must be a valid IAM role ARN."
  }
}
```

### Advanced Validation Functions

#### can()
Tests if an expression can be evaluated without errors.

```hcl
validation {
  condition     = can(regex("^[a-z]+$", var.name))
  error_message = "Name must contain only lowercase letters."
}
```

#### contains()
Checks if a list contains a value.

```hcl
validation {
  condition     = contains(["small", "medium", "large"], var.size)
  error_message = "Size must be small, medium, or large."
}
```

#### alltrue()
Checks if all values in a list are true.

```hcl
validation {
  condition = alltrue([
    length(var.name) > 0,
    length(var.name) < 100,
    can(regex("^[a-z]", var.name))
  ])
  error_message = "Name must be between 1-100 chars and start with lowercase."
}
```

---

## 9. Sensitive Variables

### Overview
Security is paramount when working with infrastructure code. Sensitive variables ensure that confidential data like passwords and API keys are protected from accidental exposure.

Sensitive variables protect confidential data from appearing in logs, console output, or state files in plain text.

### Marking Variables as Sensitive

```hcl
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
```

### What Sensitive Does

- Hides value in `terraform plan` and `terraform apply` output
- Marks value as `(sensitive value)` in logs
- Prevents accidental exposure in CI/CD logs
- Protects against accidental commits of sensitive data

### Sensitive Outputs

```hcl
output "database_password" {
  description = "Master password for the database"
  value       = aws_db_instance.main.password
  sensitive   = true
}
```

### Viewing Sensitive Outputs

```bash
# Won't show by default
terraform output

# Show sensitive value (use carefully)
terraform output -raw database_password
```

### Sensitive in Locals

```hcl
locals {
  db_connection_string = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}"
}

# Any local that references a sensitive variable becomes sensitive
```

### Best Practices

#### Use External Secret Management
```hcl
# Use AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

#### Environment Variables for Secrets
```bash
# Set as environment variable (not committed to repo)
export TF_VAR_db_password="super-secret-password"
```

#### Use .tfvars (Gitignored)
```hcl
# secrets.auto.tfvars (add to .gitignore)
db_password = "super-secret-password"
api_key     = "your-api-key"
```

```gitignore
# .gitignore
*.tfvars
!example.tfvars
terraform.tfstate
terraform.tfstate.backup
.terraform/
```

### Common Sensitive Variables

```hcl
# Database credentials
variable "db_password" {
  type      = string
  sensitive = true
}

# API keys
variable "api_key" {
  type      = string
  sensitive = true
}

# SSH keys
variable "ssh_private_key" {
  type      = string
  sensitive = true
}

# Encryption keys
variable "kms_key" {
  type      = string
  sensitive = true
}

# OAuth tokens
variable "oauth_token" {
  type      = string
  sensitive = true
}
```

### Sensitive Data in Resources

```hcl
resource "aws_db_instance" "main" {
  identifier = "mydb"
  engine     = "postgres"
  username   = var.db_username
  password   = var.db_password  # This is sensitive

  # Even though password is sensitive, other attributes are not
  instance_class = "db.t3.micro"
}
```

### Important Notes

- State files still contain sensitive data in plain text
- Use remote state with encryption (S3 with encryption, Terraform Cloud)
- Use state file encryption
- Limit access to state files
- Never commit state files to version control
- Consider using tools like SOPS or git-crypt for tfvars files

---

## 10. Best Practices

### Overview
Learning best practices helps you write professional-grade Terraform code that is maintainable, secure, and scalable. These practices reflect real-world experience from infrastructure teams.

Follow these best practices to write maintainable, secure, and scalable Terraform configurations.

### Variable Naming

```hcl
# Good: Descriptive and clear
variable "vpc_cidr_block" {}
variable "enable_dns_hostnames" {}
variable "instance_count" {}

# Bad: Vague or unclear
variable "cidr" {}
variable "dns" {}
variable "count" {}
```

### Always Add Descriptions

```hcl
# Good
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# Bad
variable "environment" {
  type = string
}
```

### Use Appropriate Types

```hcl
# Good: Specific types
variable "instance_count" {
  type = number
}

variable "tags" {
  type = map(string)
}

# Bad: Using 'any' when not necessary
variable "instance_count" {
  type = any
}
```

### Provide Sensible Defaults

```hcl
# Good: Safe defaults for non-critical values
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Bad: No default for common values
variable "instance_type" {
  type = string
}

# Good: No default for required values
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  # No default - user must provide
}
```

### Use Validation

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Organize Variables

```hcl
# variables.tf - Group related variables

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Compute Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### Use Locals for Computed Values

```hcl
locals {
  # Don't repeat yourself
  name_prefix = "${var.project_name}-${var.environment}"

  # Computed values
  subnet_count = length(var.availability_zones)

  # Merge tags
  common_tags = merge(
    var.common_tags,
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )
}
```

### Separate Environments

```bash
# Directory structure
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

### Use Variable Files

```hcl
# variables.tf - Variable definitions
variable "environment" {
  type = string
}

# dev.tfvars - Dev values
environment = "dev"
instance_type = "t2.micro"

# prod.tfvars - Prod values
environment = "prod"
instance_type = "t2.large"
```

### Document Your Variables

```hcl
# Create example.tfvars
environment    = "dev"
region         = "us-east-1"
instance_count = 1

tags = {
  Project = "MyApp"
  Team    = "DevOps"
}
```

### Use Type Constraints

```hcl
# Enforce structure
variable "vpc_config" {
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
}
```

### Security Best Practices

```hcl
# 1. Mark sensitive variables
variable "db_password" {
  type      = string
  sensitive = true
}

# 2. Never commit .tfvars with secrets
# Add to .gitignore: *.tfvars, *.tfstate

# 3. Use external secret management
data "aws_secretsmanager_secret" "db_password" {
  name = "prod/db/password"
}

# 4. Validate input
variable "allowed_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

---

## 11. Common Patterns

### Overview
Real-world patterns demonstrate how experienced infrastructure teams use variables to solve common problems. These patterns are battle-tested in production environments.

Real-world patterns for using variables effectively in Terraform.

### Pattern 1: Environment-Based Configuration

```hcl
# variables.tf
variable "environment" {
  type = string
}

variable "instance_configs" {
  type = map(object({
    instance_type  = string
    instance_count = number
    storage_size   = number
  }))

  default = {
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
      storage_size   = 20
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
      storage_size   = 50
    }
    prod = {
      instance_type  = "t2.large"
      instance_count = 5
      storage_size   = 100
    }
  }
}

# main.tf
locals {
  config = var.instance_configs[var.environment]
}

resource "aws_instance" "app" {
  count         = local.config.instance_count
  instance_type = local.config.instance_type

  root_block_device {
    volume_size = local.config.storage_size
  }
}
```

### Pattern 2: Conditional Resource Creation

```hcl
# variables.tf
variable "create_database" {
  description = "Whether to create a database instance"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

# main.tf
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0

  identifier     = "mydb"
  engine         = "postgres"
  instance_class = "db.t3.micro"
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
}
```

### Pattern 3: Dynamic Tagging

```hcl
# variables.tf
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "additional_tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

# locals.tf
locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.additional_tags
  )
}

# main.tf
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-web-${var.environment}"
      Role = "web-server"
    }
  )
}
```

### Pattern 4: Multi-Region Deployment

```hcl
# variables.tf
variable "regions" {
  type = map(object({
    cidr_block         = string
    availability_zones = list(string)
    instance_count     = number
  }))

  default = {
    us-east-1 = {
      cidr_block         = "10.0.0.0/16"
      availability_zones = ["us-east-1a", "us-east-1b"]
      instance_count     = 3
    }
    us-west-2 = {
      cidr_block         = "10.1.0.0/16"
      availability_zones = ["us-west-2a", "us-west-2b"]
      instance_count     = 2
    }
  }
}

# main.tf
module "regional_infrastructure" {
  source   = "./modules/regional"
  for_each = var.regions

  region             = each.key
  cidr_block         = each.value.cidr_block
  availability_zones = each.value.availability_zones
  instance_count     = each.value.instance_count
}
```

### Pattern 5: Feature Flags

```hcl
# variables.tf
variable "features" {
  description = "Feature flags"
  type = object({
    enable_cloudwatch = bool
    enable_backups    = bool
    enable_encryption = bool
    enable_multi_az   = bool
  })

  default = {
    enable_cloudwatch = false
    enable_backups    = true
    enable_encryption = true
    enable_multi_az   = false
  }
}

# main.tf
resource "aws_db_instance" "main" {
  identifier = "mydb"

  # Conditional features
  multi_az               = var.features.enable_multi_az
  backup_retention_period = var.features.enable_backups ? 7 : 0
  storage_encrypted      = var.features.enable_encryption

  # More config...
}

resource "aws_cloudwatch_log_group" "app" {
  count = var.features.enable_cloudwatch ? 1 : 0
  name  = "/aws/app/logs"
}
```

### Pattern 6: Naming Convention

```hcl
# variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "component" {
  type = string
}

# locals.tf
locals {
  # Standard naming: project-environment-component-resource
  name_prefix = "${var.project}-${var.environment}-${var.component}"

  # Generate resource names
  vpc_name    = "${local.name_prefix}-vpc"
  subnet_name = "${local.name_prefix}-subnet"
  sg_name     = "${local.name_prefix}-sg"
}

# main.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = local.vpc_name
  }
}
```

### Pattern 7: Cost Optimization

```hcl
# variables.tf
variable "environment" {
  type = string
}

# locals.tf
locals {
  # Use spot instances for non-prod
  use_spot_instances = var.environment != "prod"

  # Smaller instances for dev
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"

  # Fewer AZs for dev
  az_count = var.environment == "prod" ? 3 : 1

  # Shorter retention for dev
  backup_retention = var.environment == "prod" ? 30 : 7
}

# main.tf
resource "aws_instance" "app" {
  instance_type = local.instance_type

  instance_market_options {
    market_type = local.use_spot_instances ? "spot" : null
  }
}
```

### Pattern 8: Module Composition

```hcl
# variables.tf
variable "application_config" {
  type = object({
    name        = string
    environment = string

    networking = object({
      vpc_cidr = string
      azs      = list(string)
    })

    compute = object({
      instance_type  = string
      instance_count = number
    })

    database = object({
      engine         = string
      instance_class = string
    })
  })
}

# main.tf
module "networking" {
  source = "./modules/networking"

  vpc_cidr    = var.application_config.networking.vpc_cidr
  azs         = var.application_config.networking.azs
  name_prefix = var.application_config.name
}

module "compute" {
  source = "./modules/compute"

  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  instance_type  = var.application_config.compute.instance_type
  instance_count = var.application_config.compute.instance_count
}

module "database" {
  source = "./modules/database"

  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.database_subnet_ids
  engine         = var.application_config.database.engine
  instance_class = var.application_config.database.instance_class
}
```

---

## 12. AWS-Specific Examples

### Overview
Now that you understand variables comprehensively, see how they're applied in real AWS resource configurations. These examples show variables in action with common AWS infrastructure components.

Practical examples of using variables with common AWS resources.

### VPC Configuration

```hcl
# variables.tf
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

# main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = var.vpc_name
  }
}

# terraform.tfvars
vpc_name             = "production-vpc"
vpc_cidr             = "10.0.0.0/16"
enable_dns_hostnames = true
enable_dns_support   = true
```

### EC2 Instance

```hcl
# variables.tf
variable "instance_name" {
  description = "Name tag for EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Must be a valid t2/t3 instance type."
  }
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 8 and 1000 GB."
  }
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

# main.tf
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  user_data              = var.user_data

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = var.instance_name
  }
}

# terraform.tfvars
instance_name      = "web-server-01"
ami_id             = "ami-0c55b159cbfafe1f0"
instance_type      = "t3.small"
key_name           = "my-keypair"
subnet_id          = "subnet-12345678"
security_group_ids = ["sg-12345678"]
root_volume_size   = 30
```

### S3 Bucket

```hcl
# variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase letters, numbers, and hyphens."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for bucket"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable encryption for bucket"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for objects"
  type = list(object({
    id                     = string
    enabled                = bool
    transition_days        = number
    transition_storage_class = string
    expiration_days        = number
  }))
  default = []
}

variable "bucket_tags" {
  description = "Tags for S3 bucket"
  type        = map(string)
  default     = {}
}

# main.tf
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  tags   = var.bucket_tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      transition {
        days          = rule.value.transition_days
        storage_class = rule.value.transition_storage_class
      }

      expiration {
        days = rule.value.expiration_days
      }
    }
  }
}

# terraform.tfvars
bucket_name        = "my-application-bucket"
enable_versioning  = true
enable_encryption  = true

lifecycle_rules = [
  {
    id                       = "archive-old-logs"
    enabled                  = true
    transition_days          = 30
    transition_storage_class = "GLACIER"
    expiration_days          = 90
  }
]

bucket_tags = {
  Environment = "production"
  Purpose     = "application-data"
}
```

### RDS Database

```hcl
# variables.tf
variable "db_identifier" {
  description = "Database identifier"
  type        = string
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.db_engine)
    error_message = "Engine must be postgres, mysql, or mariadb."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14.5"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Password must be at least 8 characters."
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

# main.tf
resource "aws_db_instance" "main" {
  identifier     = var.db_identifier
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  multi_az               = var.multi_az
  backup_retention_period = var.backup_retention_period

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name

  skip_final_snapshot = true
}

# terraform.tfvars (secrets would be in separate file)
db_identifier          = "production-db"
db_engine              = "postgres"
db_engine_version      = "14.5"
db_instance_class      = "db.t3.small"
db_name                = "appdb"
allocated_storage      = 50
multi_az               = true
backup_retention_period = 14
vpc_security_group_ids = ["sg-12345678"]
db_subnet_group_name   = "my-db-subnet-group"

# secrets.tfvars (gitignored)
db_username = "admin"
db_password = "super-secret-password"
```

### Security Group

```hcl
# variables.tf
variable "sg_name" {
  description = "Security group name"
  type        = string
}

variable "sg_description" {
  description = "Security group description"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "Egress rules"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# main.tf
resource "aws_security_group" "main" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

# terraform.tfvars
sg_name        = "web-server-sg"
sg_description = "Security group for web servers"
vpc_id         = "vpc-12345678"

ingress_rules = [
  {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "SSH from office"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]
  }
]
```

### Load Balancer

```hcl
# variables.tf
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "Whether ALB is internal"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets."
  }
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Target group configurations"
  type = list(object({
    name     = string
    port     = number
    protocol = string
    health_check = object({
      enabled             = bool
      path                = string
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  }))
}

# main.tf
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
}

resource "aws_lb_target_group" "main" {
  for_each = { for tg in var.target_groups : tg.name => tg }

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }
}

# terraform.tfvars
alb_name           = "production-alb"
internal           = false
subnet_ids         = ["subnet-12345", "subnet-67890"]
security_group_ids = ["sg-12345678"]

target_groups = [
  {
    name     = "web-tg"
    port     = 80
    protocol = "HTTP"
    health_check = {
      enabled             = true
      path                = "/health"
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }
]
```

Happy Terraforming!
