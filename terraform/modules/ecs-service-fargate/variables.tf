variable "environment" {
  description = "Deployment environment (dev/test/prod)"
  type        = string
}

variable "cluster_arn" {
  description = "ECS Cluster ARN"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "container_image" {
  description = "Full URI of the Docker image"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
}

variable "cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MB) for the Fargate task"
  type        = number
  default     = 512
}

variable "subnet_ids" {
  description = "List of subnet IDs for the task ENI"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the task ENI"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "IAM Role ARN for ECS task execution"
  type        = string
}

variable "aws_region" {
  description = "AWS region for logs and other integrations"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Days to retain ECS CloudWatch logs"
}
