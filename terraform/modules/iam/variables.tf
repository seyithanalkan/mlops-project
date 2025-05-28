variable "environment" {
  description = "Deployment environment (dev, stage, prod)"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN of the processed data S3 bucket"
  type        = string
}

variable "model_bucket_arn" {
  description = "ARN of the model S3 bucket"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster where tasks will be run"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the ECS task definition to invoke"
  type        = string
}

variable "aws_region" {
  description = "AWS region where ECS and EventBridge live"
  type        = string
}

variable "train_task_name" {
  description = "Base name of your train ECS task (without revision)"
  type        = string
}

variable "train_task_family" {
  description = "Family name (no revision) of the Train Task Definition"
  type        = string
}

variable "serve_service_arn" {
  description = "Full ARN of the ECS service to restart"
  type        = string
}
