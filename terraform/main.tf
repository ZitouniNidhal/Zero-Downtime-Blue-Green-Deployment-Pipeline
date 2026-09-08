terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  environment        = var.environment
  app_name           = var.app_name
}

module "ec2_deployment_host" {
  source              = "./modules/ec2_deployment_host"
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.public_subnet_id
  instance_type       = var.instance_type
  ssh_public_key      = var.ssh_public_key
  key_name            = var.key_name
  allowed_cidr_blocks = var.allowed_cidr_blocks
  environment         = var.environment
  app_name            = var.app_name
  git_repo_url        = var.git_repo_url
}
