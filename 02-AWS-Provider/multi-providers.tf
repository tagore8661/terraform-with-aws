terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7" 
    }
  }
}

// Default provider (used when no provider alias is specified)
provider "aws" {
  region = "us-east-1"
  }

// Multiple provider instances (aliases) — useful for multi-region or multi-account
provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}

provider "aws" {
  alias  = "ap_south_1"
  region = "ap-south-1"
}

// Assume-role example for cross-account workflows
provider "aws" {
  alias  = "prod"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/TerraformRole"
    # external_id, session_name, and other settings are optional and can be added here
  }
}

// default_tags example (applies tags to resources created by this provider)
provider "aws" {
  alias  = "tagged"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

// Example usage: reference an aliased provider in a resource
// resource "aws_s3_bucket" "prod_bucket" {
//   provider = aws.prod
//   bucket   = "my-company-prod-bucket"
// }

// Example: passing providers into a module
// module "vpc" {
//   source = "../modules/vpc"
//   providers = {
//     aws = aws.prod
//   }
// }

// Credential methods (recommended):
// - Environment variables
// - AWS_PROFILE (shared credentials)
// - Instance / ECS task roles
// - aws sso login