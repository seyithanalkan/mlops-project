variable "environment" {
  description = "Deployment environment (dev, test, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Base name for the ECS cluster"
  type        = string
}
