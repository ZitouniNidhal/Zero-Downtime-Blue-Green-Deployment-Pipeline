variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, production)"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name for tagging and resource naming"
  type        = string
  default     = "blue-green-app"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AWS Availability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "ssh_public_key" {
  description = "Public SSH key for server access"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing AWS Key Pair name"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDRs permitted for access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "git_repo_url" {
  description = "Git Repository URL to clone on bootstrap"
  type        = string
  default     = "https://github.com/ZitouniNidhal/Zero-Downtime-Blue-Green-Deployment-Pipeline.git"
}
