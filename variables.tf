variable "aws_region" {
  description = "The AWS region"
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "AWS Key Name"
  type        = string
  sensitive   = true
}