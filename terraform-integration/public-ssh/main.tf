terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.70.0"
    }
  }
}
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "integration-test"
  secret_key                  = "integration-test-secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
}
resource "aws_security_group" "public_ssh_test" {
  name        = "opa-public-ssh-test"
  description = "Isolated policy integration test; never apply"
  vpc_id      = "vpc-0123456789abcdef0"
  ingress {
    description = "Intentionally unsafe test case"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
