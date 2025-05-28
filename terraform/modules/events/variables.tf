variable "environment" {
  type        = string
  description = "Deployment environment (dev, stage, prod)"
}

variable "raw_bucket_name" {
  type        = string
  description = "Name of the raw-data S3 bucket"
}

variable "cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster to run the task in"
}

variable "task_definition_arn" {
  type        = string
  description = "Full ARN (or ARN:*) of the ECS Task Definition to run"
}

variable "eventbridge_role_arn" {
  type        = string
  description = "ARN of the IAM Role that EventBridge assumes to call RunTask"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for Fargate networkConfiguration"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security-group IDs for Fargate networkConfiguration"
}
