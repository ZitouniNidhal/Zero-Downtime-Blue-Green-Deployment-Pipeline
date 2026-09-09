variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "bluegreen-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "max_image_count" {
  description = "Maximum number of container images to retain"
  type        = number
  default     = 10
}
