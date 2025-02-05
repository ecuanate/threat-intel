provider "aws" {
  region = "us-east-1"
}

##############################
# 1. Insecure S3 Bucket
##############################
# This S3 bucket is configured with a public-read-write ACL and
# has website hosting enabled. Public write access may allow unauthorized changes.
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "insecure-bucket-example"
  acl    = "public-read-write"  # Allows public read and write access.

  versioning {
    enabled = true
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

##############################
# 2. Open Security Group
##############################
# This security group allows SSH (port 22) access from any IP address.
resource "aws_security_group" "insecure_sg" {
  name        = "insecure-sg"
  description = "Security group with open SSH access"
  vpc_id      = "vpc-12345678"  # Replace with a valid VPC ID.

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the entire internet.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# 3. Misconfigured RDS Instance
##############################
# This RDS instance is publicly accessible and lacks storage encryption,
# which could expose sensitive data.
resource "aws_db_instance" "insecure_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "insecuredb"
  username             = "admin"
  password             = "SuperSecretPassword"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = true   # Public access enabled.
  storage_encrypted    = false  # Data is not encrypted at rest.
}

##############################
# 4. Overly Permissive IAM User
##############################
# This IAM user has an inline policy that allows all actions on all resources.
resource "aws_iam_user" "insecure_user" {
  name = "insecure-user"
}

resource "aws_iam_user_policy" "insecure_policy" {
  name = "insecure-policy"
  user = aws_iam_user.insecure_user.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

##############################
# 5. Insecure Lambda Function
##############################
# This Lambda function uses environment variables to store secrets in plain text.
resource "aws_lambda_function" "insecure_lambda" {
  filename         = "lambda_function_payload.zip"  # Ensure this file exists in your working directory.
  function_name    = "insecure_lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      SECRET_KEY = "insecure-secret-key"
      API_TOKEN  = "insecure-api-token"
    }
  }
}

# IAM role for Lambda execution.
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
