terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "tls_private_key" "rsa_4096_terraform" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair_terraform" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096_terraform.public_key_openssh
  }

resource "local_file" "private_key" {
  content = tls_private_key.rsa_4096_terraform.private_key_pem
  filename = var.key_name
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "web" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair_terraform.key_name
  tags = {
    Name = "terraform_instance"
  }
}