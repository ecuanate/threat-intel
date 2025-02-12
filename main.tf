#################################################
# Terraform & AWS Provider Requirements
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
# KMS Key (Customer-Managed) for S3 SSE
#################################################
# This key is used to encrypt S3 objects at rest.
# It is more secure than using the default SSE-S3 key.
#################################################
data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [
        # This allows the account root (and by extension IAM users/roles)
        # in your account to manage the key.
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "Customer-managed KMS key for S3 bucket encryption"
  deletion_window_in_days = 10  # Adjust as desired
  enable_key_rotation     = true  # Rotates key annually
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

#################################################
# S3 Bucket (Private, Versioned, Encrypted)
#################################################
resource "aws_s3_bucket" "example" {
  # Replace with your unique bucket name
  bucket = "my-very-secure-bucket-12345"
  acl    = "private"

  # Versioning
  versioning {
    enabled = true
  }

  # Server-side encryption with the KMS key above
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.arn
      }
    }
  }
}

#################################################
# Block Public Access
#################################################
# This ensures no ACLs or bucket policies can grant
# public access to the bucket or objects.
#################################################
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
