terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "tagore8661-bucket"

  tags = {
    Name        = "My Bucket"
    Environment = "Testing"
  }
}
