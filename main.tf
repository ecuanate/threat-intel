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

#################################################
# Logging Bucket - for storing access logs
#################################################
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-very-secure-log-bucket-12345"
  acl    = "log-delivery-write"

  # (Optional) Keep it private as well
  # This ensures logs are also protected
  block_public_access {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

#################################################
# Main Bucket
#################################################
resource "aws_s3_bucket" "example" {
  bucket = "my-very-secure-bucket-12345"
  acl    = "private"

  # (Optional) Enable versioning
  versioning {
    enabled = true
  }

  # Enable server-side encryption (optional, but recommended)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Enable access logging to the log_bucket
  logging {
    target_bucket = aws_s3_bucket.log_bucket.bucket
    target_prefix = "example-bucket-logs/"
  }
}

#################################################
# Block Public Access for the Main Bucket
#################################################
resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
