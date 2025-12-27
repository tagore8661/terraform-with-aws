# Amazon S3 Bucket Management with Terraform

## Table of Contents
1. [What is Amazon S3?](#what-is-amazon-s3)
2. [Creating S3 Buckets with Terraform](#creating-s3-buckets-with-terraform)
3. [S3 Bucket Configuration](#s3-bucket-configuration)
4. [S3 Bucket Policies & Access Control](#s3-bucket-policies--access-control)
5. [S3 Versioning & Lifecycle](#s3-versioning--lifecycle)
6. [S3 Encryption & Security](#s3-encryption--security)
7. [S3 Monitoring & Logging](#s3-monitoring--logging)
8. [S3 with CloudFront (CDN)](#s3-with-cloudfront-cdn)
9. [Best Practices](#best-practices)
10. [Common Use Cases](#common-use-cases)
11. [Troubleshooting](#troubleshooting)
12. [Cost Optimization](#cost-optimization)
13. [Real-World Examples](#real-world-examples)

---

## What is Amazon S3?

### The Simple Definition

**Amazon Simple Storage Service (S3)** is like a massive, reliable filing cabinet in the cloud. You can store any type of file (documents, images, videos, code, backups) and access them from anywhere in the world.

### How It Works

```
Your Computer          AWS Cloud (S3)
─────────────          ──────────────

    File ──────→    S3 Bucket (Container)
                          ├── Document.pdf
                          ├── Image.jpg
                          ├── Backup.zip
                          └── Video.mp4

    Download   ←────── Access anytime, anywhere
```

### Real-World Analogy

Think of S3 like a bank's vault system:
- **Bucket** = A large locked vault
- **Objects** = Individual items stored in the vault
- **Keys** = Reference names for finding items
- **Regions** = Different bank branches

### Core Characteristics

| Feature | Description |
|---------|-------------|
| **Unlimited Storage** | Store as much as you need, pay only for what you use |
| **High Durability** | 99.999999999% (11 nines) - one of the highest in the industry |
| **99.99% Availability** | Your data is always accessible |
| **Global Access** | Access from anywhere with internet |
| **Pay-Per-Use** | Only pay for storage and transfer you actually use |
| **Managed Service** | AWS handles all maintenance and infrastructure |

---

## Creating S3 Buckets with Terraform

### 1. Simple S3 Bucket

**Easiest possible bucket:**

```hcl
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"

  tags = {
    Name        = "My Bucket"
    Environment = "Development"
  }
}
```

**Create & verify:**
```bash
terraform init
terraform plan
terraform apply

# Verify in AWS
aws s3 ls | grep my-unique-bucket-name
```

### 2. Production-Ready Bucket

```hcl
resource "aws_s3_bucket" "production_bucket" {
  bucket = "company-production-data-2024"

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion
  }

  tags = {
    Name        = "Production Data Bucket"
    Environment = "Production"
    Owner       = "DataTeam"
    CostCenter  = "Engineering"
  }
}
```

### 3. Bucket with All Configurations

```hcl
resource "aws_s3_bucket" "advanced_bucket" {
  bucket = "my-advanced-bucket-2024"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Advanced Bucket"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "advanced_bucket_versioning" {
  bucket = aws_s3_bucket.advanced_bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"  # Set to Enabled for extra protection
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "advanced_bucket_encryption" {
  bucket = aws_s3_bucket.advanced_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "advanced_bucket_pab" {
  bucket = aws_s3_bucket.advanced_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "advanced_bucket_logging" {
  bucket = aws_s3_bucket.advanced_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "advanced_bucket_lifecycle" {
  bucket = aws_s3_bucket.advanced_bucket.id

  rule {
    id     = "archive-old-files"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

---

## S3 Bucket Configuration

### 1. Versioning

**What it does**: Keeps all versions of your files.

**Enable versioning:**
```hcl
resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}
```

**Benefits:**
- Recover from accidental deletions
- Track file history
- Compliance requirements

**Version Example:**
```
Upload: document.txt (version: null-default)
Update: document.txt (version: abc123)
Delete: document.txt (version: xyz789 - marked as deleted)
Restore: Access version abc123 to recover
```

### 2. Bucket Tagging

**Add metadata to buckets:**

```hcl
resource "aws_s3_bucket_tagging" "my_bucket_tagging" {
  bucket = aws_s3_bucket.my_bucket.id

  tags = {
    Name           = "My Application Bucket"
    Environment    = "Production"
    Owner          = "DataTeam"
    CostCenter     = "Engineering"
    Project        = "Analytics"
    DataClassification = "Sensitive"
  }
}
```

**Use cases:**
- Cost allocation
- Resource organization
- Access control
- Automated management

### 3. Static Website Hosting

**Host a static website:**

```hcl
resource "aws_s3_bucket_website_configuration" "my_bucket_website" {
  bucket = aws_s3_bucket.my_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Make bucket public for website
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}

# Output website URL
output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.my_bucket_website.website_endpoint
  description = "Website endpoint URL"
}
```

**Website URL:**
```
http://my-bucket.s3-website-us-east-1.amazonaws.com
```

### 4. CORS Configuration

**Allow cross-origin requests:**

```hcl
resource "aws_s3_bucket_cors_configuration" "my_bucket_cors" {
  bucket = aws_s3_bucket.my_bucket.id

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://example.com", "https://app.example.com"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    allowed_headers = ["Authorization"]
  }
}
```

**Use case**: JavaScript in web browser accessing S3 directly.

### 5. Request Payment

**Require requestor to pay for data transfer:**

```hcl
resource "aws_s3_bucket_request_payment_configuration" "my_bucket_payment" {
  bucket = aws_s3_bucket.my_bucket.id

  payer = "Requester"  # or "BucketOwner"
}
```

**Use case**: Large data sharing where you want users to pay for bandwidth.

---

## S3 Bucket Policies & Access Control

### 1. Public Read Access

**Allow everyone to read objects:**

```hcl
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}
```

### 2. IAM User Access

**Allow specific IAM user/role:**

```hcl
resource "aws_s3_bucket_policy" "iam_user_access" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIAMUserAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:user/john"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}
```

### 3. EC2 Instance Access

**Allow EC2 instance via IAM role:**

```hcl
# Create IAM role
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name   = "ec2-s3-access-policy"
  role   = aws_iam_role.ec2_s3_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.ec2_s3_role.name
}
```

### 4. Block Public Access (Security Best Practice)

**Prevent accidental public exposure:**

```hcl
resource "aws_s3_bucket_public_access_block" "my_bucket_pab" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true   # Ignore public ACLs
  block_public_policy     = true   # Ignore public bucket policies
  ignore_public_acls      = true   # Treat public as private
  restrict_public_buckets = true   # Restrict public access
}
```

### 5. VPC Endpoint Access

**Access S3 from VPC without internet gateway:**

```hcl
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [aws_route_table.main.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}
```

---

## S3 Versioning & Lifecycle

### 1. Lifecycle Policies

**Automatically manage object lifecycle:**

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "transition-to-cheaper-storage"
    status = "Enabled"

    # Move to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 365 days
    expiration {
      days = 365
    }
  }

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    # Delete non-current versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    # Move old versions to Glacier
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
  }
}
```

**Lifecycle Rules Explained:**

```
Timeline for an object:
────────────────────────────────────────────────────────

Day 0:      Object created (S3 Standard)
            (Frequently accessed, full cost)

Day 30:     Transition to Standard-IA
            (Infrequent access, lower cost)

Day 90:     Transition to Glacier
            (Archive, much lower cost)
            (10-30 minute retrieval time)

Day 365:    Expiration (Delete)
            (No longer stored, no cost)
```

### 2. Expiration Rules

**Delete objects after certain conditions:**

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "expiration_rules" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "delete-logs-after-90-days"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "delete-temp-files"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 1
    }
  }

  rule {
    id     = "delete-by-tag"
    status = "Enabled"

    filter {
      tag {
        key   = "auto-delete"
        value = "true"
      }
    }

    expiration {
      days = 30
    }
  }
}
```

### 3. Versioning with Lifecycle

**Keep limited versions:**

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "version_management" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "manage-versions"
    status = "Enabled"

    # Keep only 5 versions
    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    # Or keep versions for 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Transition old versions to cheaper storage
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
  }
}
```

---

## S3 Encryption & Security

### 1. Server-Side Encryption (SSE-S3)

**AWS-managed encryption (default):**

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_s3" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true  # Improves performance
  }
}
```

**Cost**: Included (no additional charge)
**Key Management**: AWS managed
**Performance**: Optimal

### 2. Server-Side Encryption (SSE-KMS)

**Customer-managed encryption with KMS:**

```hcl
# Create KMS key
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "S3-Encryption-Key"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-encryption"
  target_key_id = aws_kms_key.s3_key.key_id
}

# Configure S3 to use KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_kms" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = "aws:kms"
      kms_master_key_id  = aws_kms_key.s3_key.arn
    }
    bucket_key_enabled = true
  }
}
```

**Cost**: Additional charges for KMS usage
**Key Management**: You control encryption keys
**Use Case**: Sensitive data requiring key rotation and audit

### 3. Client-Side Encryption

**Encrypt before uploading to S3:**

```python
# Example Python code (not Terraform)
import boto3
from cryptography.fernet import Fernet

s3_client = boto3.client('s3')
cipher = Fernet(encryption_key)

with open('document.pdf', 'rb') as f:
    file_data = f.read()
    encrypted_data = cipher.encrypt(file_data)

s3_client.put_object(
    Bucket='my-bucket',
    Key='secure/document.pdf',
    Body=encrypted_data
)
```

### 4. SSL/TLS for Data in Transit

**Force HTTPS connections:**

```hcl
resource "aws_s3_bucket_policy" "ssl_only" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceSSLOnly"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.my_bucket.arn,
          "${aws_s3_bucket.my_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

### 5. Object-Level ACL Control

**Control access per object:**

```hcl
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id

  acl = "private"  # or "public-read", "public-read-write", etc.
}
```

**ACL Options:**
```
private             - Owner read/write only
public-read         - Owner: read/write, Others: read
public-read-write   - Everyone: read/write (not recommended)
authenticated-read  - Owner: read/write, Any AWS account: read
```

---

## S3 Monitoring & Logging

### 1. S3 Access Logging

**Log all requests to your bucket:**

```hcl
# Create logging bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-bucket-logs"

  tags = {
    Name = "Log Bucket"
  }
}

# Allow S3 to write logs
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

# Enable logging on main bucket
resource "aws_s3_bucket_logging" "my_bucket_logging" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "access-logs/"
}
```

**Log Format:**
```
bucket-owner-id request-id [timestamp] source-ip requester-id operation object-key response-status
123456789012 3E57427F3EXAMPLE [06/Feb/2021:00:00:38 +0000] 192.0.2.3 arn:aws:iam::123456789012:user/John GET /bucket/key 200
```

### 2. CloudWatch Metrics

**Monitor bucket metrics:**

```hcl
resource "aws_s3_bucket_metric" "entire_bucket" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_metric" "documents_prefix" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "DocumentsMetrics"

  prefix = "documents/"
}

resource "aws_s3_bucket_metric" "logs_with_tag" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "LogsWithTag"

  filter {
    prefix = "logs/"

    tags = {
      LogType = "Application"
    }
  }
}
```

### 3. CloudTrail Integration

**Audit API calls:**

```hcl
resource "aws_cloudtrail" "s3_audit" {
  name           = "s3-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
  is_multi_region_trail = true
  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.my_bucket.arn}/*"]
    }
  }
}
```

### 4. CloudWatch Alarms

**Alert on unusual activity:**

```hcl
resource "aws_cloudwatch_metric_alarm" "high_request_rate" {
  alarm_name          = "s3-high-request-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = 100000

  dimensions = {
    BucketName = aws_s3_bucket.my_bucket.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

---

## S3 with CloudFront (CDN)

### 1. CloudFront Distribution

**Serve content globally with CDN:**

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = true

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Create Origin Access Identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket"
}

# Update bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cloudfront_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}
```

**Output CDN URL:**
```hcl
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront distribution domain"
}
```

---

## Best Practices

### 1. Naming Conventions

```hcl
# Good bucket naming
"company-data-production-us-east-1"
"user-uploads-staging"
"analytics-logs-2024"

# Avoid
"MyBucket" (uppercase)
"bucket_with_underscores"
"backup123" (not descriptive)
"my-bucket-that-contains-many-things"
```

### 2. Bucket Organization

```hcl
bucket_structure:
├── documents/
│   ├── 2024/
│   │   ├── january/
│   │   └── february/
│   └── 2023/
├── images/
│   ├── user-avatars/
│   └── products/
├── backups/
│   ├── database/
│   └── application/
└── temp/
    └── uploads/
```

### 3. Security Best Practices

```hcl
# Enable all protections
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce SSL/TLS
resource "aws_s3_bucket_policy" "enforce_ssl" {
  bucket = aws_s3_bucket.my_bucket.id
  # (policy shown earlier)
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.my_bucket.id
  # (configuration shown earlier)
}

# Enable versioning
resource "aws_s3_bucket_versioning" "version" {
  bucket = aws_s3_bucket.my_bucket.id
  # (configuration shown earlier)
}
```

### 4. Cost Optimization

**Use lifecycle policies to reduce costs:**

```hcl
# Move old data to cheaper storage automatically
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimization" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "cost-optimization"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555  # 7 years
    }
  }
}
```

### 5. Disaster Recovery

```hcl
# Enable versioning for recovery
resource "aws_s3_bucket_versioning" "recovery" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable MFA delete protection
resource "aws_s3_bucket_versioning" "mfa_delete" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled"  # Requires MFA to delete
  }
}

# Regular backups
resource "aws_backup_vault" "s3_backups" {
  name = "s3-backup-vault"
}
```

### 6. Monitoring & Alerting

```hcl
# Enable detailed monitoring
resource "aws_s3_bucket_metric" "monitor" {
  bucket = aws_s3_bucket.my_bucket.id
  name   = "EntireBucket"
}

# Alert on unusual activity
resource "aws_cloudwatch_metric_alarm" "unusual_activity" {
  alarm_name          = "s3-unusual-activity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

---

## Common Use Cases

### 1. Website Hosting

```hcl
# Simple static website
resource "aws_s3_bucket" "website" {
  bucket = "mycompany-website-2024"
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
}
```

### 2. Application Backups

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "company-backups-vault"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "backups_version" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_retention" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = 90  # Keep backups for 3 months
    }
  }
}
```

### 3. Data Lake

```hcl
resource "aws_s3_bucket" "data_lake" {
  bucket = "company-data-lake"
}

resource "aws_s3_bucket_versioning" "data_lake_version" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_encrypt" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.data_lake.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake_privacy" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 4. Log Storage

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "company-logs-archive"
}

resource "aws_s3_bucket_lifecycle_configuration" "log_retention" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "archive-logs"
    status = "Enabled"

    filter {
      prefix = "application-logs/"
    }

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

### 5. Media Distribution

```hcl
resource "aws_s3_bucket" "media" {
  bucket = "company-media-library"
}

# CloudFront for global distribution
resource "aws_cloudfront_distribution" "media_cdn" {
  origin {
    domain_name = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id   = "S3"
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

---

## Troubleshooting

### Problem 1: "Bucket Already Exists"

**Error**: `BucketAlreadyExists: The requested bucket name is not available`

**Cause**: S3 bucket names must be globally unique

**Solution**:
```hcl
# Use unique bucket name with timestamp or organization id
resource "aws_s3_bucket" "my_bucket" {
  bucket = "mycompany-bucket-${formatdate("YYYY-MM-DD", timestamp())}"
}
```

### Problem 2: "Access Denied"

**Error**: `NoSuchBucket: The specified bucket does not exist`

**Causes**:
- Insufficient IAM permissions
- Bucket doesn't exist in the region
- Bucket policy is too restrictive

**Solutions**:
```hcl
# Check IAM permissions
aws s3api get-bucket-acl --bucket my-bucket

# Verify bucket exists
aws s3 ls

# List buckets in specific region
aws s3api list-buckets --region us-east-1
```

### Problem 3: "Object not Found"

**Error**: `NoSuchKey: The specified key does not exist`

**Solution**:
```bash
# List objects in bucket
aws s3 ls s3://my-bucket/

# List objects with prefix
aws s3 ls s3://my-bucket/path/to/objects/
```

### Problem 4: "Multipart Upload Failed"

**Error**: `InvalidRequest: Invalid Part Order`

**Solution**:
```bash
# List incomplete uploads
aws s3api list-multipart-uploads --bucket my-bucket

# Abort incomplete upload
aws s3api abort-multipart-upload \
  --bucket my-bucket \
  --key object-key \
  --upload-id upload-id
```

### Problem 5: "Large File Upload Timeout"

**Solution - Use Terraform to enable Transfer Acceleration**:
```hcl
resource "aws_s3_bucket_accelerate_configuration" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  status = "Enabled"
}
```

Or use AWS CLI with transfer acceleration:
```bash
aws s3 cp large-file.zip s3://my-bucket/ --region us-east-1 --sse AES256
```

---

## Cost Optimization

### 1. Storage Pricing (per GB/month, US East Region)

```
S3 Standard:           $0.023
S3 Standard-IA:        $0.0125
S3 One Zone-IA:        $0.01
S3 Intelligent-Tiering: $0.0125
S3 Glacier Flexible:    $0.004
S3 Glacier Deep Archive: $0.00099
```

### 2. Cost Calculation Example

**Store 100 GB of data:**

```
Option 1 (S3 Standard - accessed frequently):
100 GB × $0.023 = $2.30/month = $27.60/year

Option 2 (S3 Standard-IA - accessed infrequently):
100 GB × $0.0125 = $1.25/month = $15/year
PLUS Retrieval cost (~$0.01/GB) when accessed

Option 3 (Lifecycle policy - optimal):
First 30 days in Standard: 100 GB × $0.023 = $2.30
Next 60 days in Standard-IA: 100 GB × $0.0125 = $1.25
After 90 days in Glacier: 100 GB × $0.004 = $0.40
Average: ~$0.60/month = $7.20/year
```

### 3. Cost Optimization Strategies

**Strategy 1: Lifecycle Policies**
```hcl
# Automatically move old data to cheaper storage
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimize" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    id     = "optimize-cost"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"  # Save 45%
    }

    transition {
      days          = 90
      storage_class = "GLACIER"      # Save 83%
    }

    expiration {
      days = 365
    }
  }
}
```

**Strategy 2: Intelligent-Tiering**
```hcl
resource "aws_s3_bucket" "auto_tiering" {
  bucket = "my-auto-tiering-bucket"
}

# Automatically moves data between access tiers
resource "aws_s3_bucket_intelligent_tiering_configuration" "config" {
  bucket = aws_s3_bucket.auto_tiering.id
  name   = "EntireBucket"
  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
```

**Strategy 3: S3 Select**
```bash
# Read only needed data from objects
# Reduces data transfer costs

aws s3api select-object-content \
  --bucket my-bucket \
  --key data.csv \
  --expression "SELECT * FROM s3object WHERE age > 21" \
  --expression-type SQL \
  --input-serialization '{CSV:{}}' \
  --output-serialization '{CSV:{}}' \
  output.csv
```

### 4. Monitor Costs

```hcl
resource "aws_budgets_budget" "s3_budget" {
  name              = "S3-Monthly-Budget"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_value       = "100"
  time_period_start = "2024-01-01"
  time_period_end   = "2025-12-31"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_delivery_type = "EMAIL"
    subscriber_email_addresses = ["admin@example.com"]
  }
}
```

---

## Real-World Examples

### Example 1: Complete Production S3 Setup

```hcl
# variables.tf
variable "environment" {
  default = "production"
}

variable "project_name" {
  default = "myapp"
}

variable "backup_retention_days" {
  default = 30
}

# main.tf
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

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Primary bucket
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Main Application Bucket"
  }
}

# Logging bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-logs"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "S3 Access Logs"
  }
}

resource "aws_s3_bucket_acl" "logs_acl" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

# Enable logging
resource "aws_s3_bucket_logging" "main_logging" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access-logs/"
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main_versioning" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main_encryption" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main_pab" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "main_lifecycle" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.backup_retention_days
    }
  }

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 1
    }
  }
}

# SSL enforcement policy
resource "aws_s3_bucket_policy" "main_policy" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceSSLOnly"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# outputs.tf
output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "Name of the S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "ARN of the S3 bucket"
}

output "bucket_region" {
  value       = aws_s3_bucket.main.region
  description = "AWS region of the bucket"
}
```

### Example 2: Website Hosting with CDN

```hcl
# Create S3 bucket for website
resource "aws_s3_bucket" "website" {
  bucket = "mycompany-website"
}

# Block public access (CloudFront will handle distribution)
resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create CloudFront origin access identity
resource "aws_cloudfront_origin_access_identity" "website_oai" {
  comment = "OAI for website bucket"
}

# Allow CloudFront to access S3
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CloudFrontAccess"
      Effect = "Allow"
      Principal = {
        AWS = aws_cloudfront_origin_access_identity.website_oai.iam_arn
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.website.arn}/*"
    }]
  })
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3Website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "Website CDN"
  }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.website.domain_name
}
```

### Example 3: Data Lake Setup

```hcl
# Create data lake bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "company-data-lake"

  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning for audit trail
resource "aws_s3_bucket_versioning" "data_lake_version" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS key for encryption
resource "aws_kms_key" "data_lake_key" {
  description             = "KMS key for data lake encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "data_lake_key_alias" {
  name          = "alias/data-lake-key"
  target_key_id = aws_kms_key.data_lake_key.key_id
}

# Enable KMS encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_encrypt" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = "aws:kms"
      kms_master_key_id  = aws_kms_key.data_lake_key.arn
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data_lake_pab" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"

    filter {
      prefix = "raw-data/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# Enable metrics for monitoring
resource "aws_s3_bucket_metric" "data_lake_metric" {
  bucket = aws_s3_bucket.data_lake.id
  name   = "EntireBucket"
}

output "data_lake_bucket" {
  value = aws_s3_bucket.data_lake.id
}
```