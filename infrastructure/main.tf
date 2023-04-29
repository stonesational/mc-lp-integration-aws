terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.aws_region
  default_tags {
    tags = var.default_tags
  }
}

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "3.19.0"
  name                   = "Navomi VPC"
  cidr                   = "10.1.0.0/16"
  azs                    = ["${var.aws_region}a", "${var.aws_region}c"]
  public_subnets         = ["10.1.100.0/24", "10.1.101.0/24"]
  private_subnets        = ["10.1.0.0/24", "10.1.1.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
}




