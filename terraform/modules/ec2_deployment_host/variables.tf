variable "vpc_id" {
  description = "VPC ID where EC2 instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be launched"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for the instance (Ubuntu 22.04 / 24.04 recommended)"
  type        = string
  default     = "" # If empty, dynamic lookup will be used
}

variable "ssh_public_key" {
  description = "Public SSH key for ec2-user / ubuntu user SSH access"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing AWS Key Pair name (optional if ssh_public_key is provided)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH and HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name tag"
  type        = string
  default     = "blue-green-app"
}

variable "git_repo_url" {
  description = "Git Repository URL to clone on setup"
  type        = string
  default     = "https://github.com/ZitouniNidhal/Zero-Downtime-Blue-Green-Deployment-Pipeline.git"
}
