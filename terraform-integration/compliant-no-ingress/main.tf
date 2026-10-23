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
resource "aws_security_group" "compliant_no_ingress" {
  name        = "opa-compliant-no-ingress"
  description = "Isolated compliant policy integration test; never apply"
  vpc_id      = "vpc-0123456789abcdef0"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
