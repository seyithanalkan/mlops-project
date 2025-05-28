variable "task_name" {
  description = "Name of the ECS task"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "container_image" {
  description = "Docker image to use for the container"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "CPU units for the task"
  type        = string
}

variable "memory" {
  description = "Memory for the task in MiB"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "command" {
  description = "Command to run in the container"
  type        = list(string)
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the task"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for the task"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "Name of the ECS cluster (for in‐container env var ECS_CLUSTER)"
  type        = string
}

variable "serve_service_name" {
  description = "Name of the ECS service to update (for env var ECS_SERVICE)"
  type        = string
}