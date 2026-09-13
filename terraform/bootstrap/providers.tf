terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Deliberately local state — see README.md for why this config can't use
  # the S3 backend it manages.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "togglemaster"
      ManagedBy = "terraform-bootstrap"
    }
  }
}
