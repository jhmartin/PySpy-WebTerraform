terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }
  }
}

provider "aws" {
  shared_config_files = [var.tfc_aws_dynamic_credentials.default.shared_config_file]
  region              = "us-west-2"
  default_tags {
    tags = {
      Project = "PySpy"
    }
  }
}

provider "aws" {
  alias               = "ue1"
  shared_config_files = [var.tfc_aws_dynamic_credentials.default.shared_config_file]
  region              = "us-east-1"
  default_tags {
    tags = {
      Project = "PySpy"
    }
  }
}
