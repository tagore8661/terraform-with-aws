# AWS Provider - Terraform

## What are Terraform Providers?
Providers are plugins that enable Terraform to interact with cloud platforms, SaaS services, and other APIs. The AWS provider (`hashicorp/aws`) implements resources and data sources to manage AWS services via AWS APIs.

Providers translate Terraform HCL definitions into API calls and implement create/read/update/delete (CRUD) operations required to manage those resources.

---

## Provider vs Terraform Core
- **Terraform Core:** The binary that parses HCL, builds plans, and orchestrates apply/refresh operations.
- **Providers:** Separate plugins (e.g., `hashicorp/aws`) that communicate with external APIs. They are versioned and released independently of Terraform Core.

Always check provider release notes and compatibility when planning upgrades.

---

## Why Provider Versioning Matters
- **Compatibility:** New provider versions may require newer Terraform Core features or change behaviors.
- **Stability:** Pinning prevents accidental upgrades that can break code.
- **New features & fixes:** Provider releases add resource support, arguments, and bug/security fixes.
- **Reproducibility:** Lock files and pinned versions ensure consistent behavior across machines and CI.

---

## Version Constraints (examples)
Declare provider constraints in the `required_providers` block:
- `= 1.2.3` — exact version
- `>= 1.2` — greater than or equal to
- `<= 1.2` — less than or equal to
- `~> 1.2` — pessimistic (allows `1.x`..`1.10` NOT `2.0`)
- `>= 1.2, < 2.0` — range constraint

Example:
### Basic Provider
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"         //Provider Version (Cloud Provider)
    }
  }
  required_version = ">= 1.0"      //Terraform Code Version
}

provider "aws" {
  region = "us-east-1"             //Provider Configs
}
```

### Multiple Providers
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    random = {
      source  = "hashicorp/random" //Other Providers (Generates Random Valus for Different Use Cases)
      version = "~> 3.1"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"          
}
```


---

## Locking Providers & Reproducible Installs
- `terraform init` creates `.terraform.lock.hcl` recording provider versions and checksums.
- Commit `.terraform.lock.hcl` to version control to ensure consistent provider installs in CI and for collaborators.
- Use `terraform providers lock` to add or update lock entries for specific platforms when necessary.
- To intentionally upgrade pinned providers, run `terraform init -upgrade` in a safe environment and review changes.

---

## Authentication & Credential Sources
Terraform (via the AWS provider) supports multiple credential sources. Common methods:
- Shared credentials file (`~/.aws/credentials`) and profiles
- Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_PROFILE`, `AWS_DEFAULT_REGION`)
- AWS CLI SSO (`aws sso login` + `AWS_PROFILE`)
- AssumeRole (configured in provider block)
- Instance metadata / ECS task role (for resources running in AWS)
- External credential helpers (e.g., `credential_process` in `~/.aws/config`)

Credential resolution order (simplified):
1. Provider explicit configuration (access_key/secret_key in code — discouraged)
2. Environment variables
3. Shared credentials file (`~/.aws/credentials`) / `AWS_PROFILE`
4. AWS config file (`~/.aws/config`)
5. EC2/ECS instance metadata / task role

Security tip: Avoid storing secrets in code or checked-in tfvars; prefer roles, environment variables, or secret stores.

---

## Provider Meta-Arguments & Notes
- `alias`: Configure multiple provider instances (regions/accounts). Reference via `provider = aws.alias` in resources.
- `region`, `profile`: Standard provider config options.
- `assume_role`: Allows cross-account roles to be used by the provider.
- `default_tags`: Set default tags applied to provider-managed resources.
- Validation skips: `skip_credentials_validation`, `skip_region_validation` — useful in certain automation cases.
- Custom endpoints: `endpoints` override for local testing or alternate endpoints.

Example using alias and assume_role:
```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "prod"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
  }
}

resource "aws_s3_bucket" "prod_bucket" {
  provider = aws.prod
  bucket   = "my-prod-bucket"
}
```

---

## Useful Commands
- `terraform init` — initialize and download providers
- `terraform providers` — lists providers used and where configured
- `terraform init -upgrade` — upgrade providers within constraints
- `terraform providers lock` — generate/update lock entries
- Inspect `.terraform.lock.hcl` to verify locked versions

---

## Useful Links
- Provider registry (AWS): https://registry.terraform.io/providers/hashicorp/aws
- Terraform CLI docs: https://www.terraform.io/docs/cli
