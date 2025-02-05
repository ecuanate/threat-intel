provider "aws" {
  region = "us-east-1"
}

# Insecure S3 bucket: Public read access, versioning disabled.
resource "aws_s3_bucket" "bad_bucket" {
  bucket        = "bad-bucket-example"
  acl           = "public-read"  # Allows public read access.
  force_destroy = true

  versioning {
    enabled = false
  }
  
  # Although encryption is configured here, the public ACL is still a risk.
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Insecure Security Group: Allows all inbound traffic on all TCP ports.
resource "aws_security_group" "bad_sg" {
  name        = "bad-sg"
  description = "Security group with overly permissive inbound rules"
  vpc_id      = "vpc-12345678"  # Replace with your actual VPC ID.

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Insecure EC2 Instance: Contains hardcoded secrets in user data.
resource "aws_instance" "bad_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Example AMI; update as needed.
  instance_type = "t2.micro"
  key_name      = "bad-key"  # Replace with your key pair.

  vpc_security_group_ids = [aws_security_group.bad_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "username=admin" >> /etc/config.conf
    echo "password=SuperSecret123" >> /etc/config.conf  # Hardcoded credentials.
  EOF
}

# Insecure IAM Role: Role that can be assumed by EC2.
resource "aws_iam_role" "bad_role" {
  name = "bad-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Insecure IAM Policy: Grants full permissions on all resources.
resource "aws_iam_role_policy" "bad_policy" {
  name = "bad-policy"
  role = aws_iam_role.bad_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
