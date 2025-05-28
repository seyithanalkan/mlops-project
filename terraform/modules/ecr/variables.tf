variable "environment" {
  description = "Deployment environment (dev, stage, prod)"
  type        = string
}

variable "repo_name" {
  description = "Name of the ECR repository (without environment suffix)"
  type        = string
}
