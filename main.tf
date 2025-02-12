#################################################
# Terraform Configuration & AWS Provider
#################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

#################################################
# KMS Key & Policy for SSE Encryption
#################################################
resource "aws_kms_key" "this" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [
        # Grant full access to your AWS account root
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
}

#################################################
# Secure S3 Bucket
#################################################
resource "aws_s3_bucket" "example" {
  bucket = "my-very-secure-bucket-12345"

  # 1. Private ACL
  acl = "private"

  # 2. Block Public Access
  block_public_access {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  # 3. Versioning
  versioning {
    enabled = true
  }

  # 4. SSE with KMS
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.this.arn
      }
    }
  }

  tags = {
    Name        = "MyVerySecureBucket"
    Environment = "Production"
  }
}

#################################################
# Deny Insecure (HTTP) Access
#################################################
data "aws_iam_policy_document" "deny_insecure_traffic" {
  statement {
    sid     = "DenyInsecureTraffic"
    effect  = "Deny"

    # Apply to this S3 bucket and its objects
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]

    # Deny if requests are not using TLS/SSL
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    # Applies to all principals
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "deny_insecure_traffic" {
  bucket = aws_s3_bucket.example.bucket
  policy = data.aws_iam_policy_document.deny_insecure_traffic.json
}
