variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment (dev, test, prod gibi)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR Block"
  type        = string
}


variable "subnet_bits" {
  description = "Subnet Bits"
  type        = number
  default     = 8
}

variable "train_repo_name" {
  description = "ECR Repo Name for Train"
  type        = string
}

variable "serve_repo_name" {
  description = "ECR Repo Name for Serve"
  type        = string
}

variable "cluster_name" {
  description = "Base Name for the ECS Cluster"
  type        = string
}


variable "raw_bucket_name" { 
  description = "Raw Data Bucket Name"
  type = string 
}
variable "processed_bucket_name" { 
  description = "Processed Data Bucket Name"
  type = string 
}

variable "model_bucket_name" {
  description = "Name of the Model-artifact S3 bucket"
  type        = string
}


variable "serve_service_name" {
  description = "ECS Fargate Service Name"
  type        = string
}

variable "serve_container_port" {
  description = "Serve Container Port"
  type        = number
}

variable "serve_cpu" {
  description = "Serve Task CPU"
  type        = number
}

variable "serve_memory" {
  description = "Serve Task  Memory"
  type        = number
}

variable "train_task_name" { 
  description = "Train Task  Name"
  type = string 
}
variable "train_cpu" { 
  description = "Train Task CPU"
  type = number 
}
variable "train_memory" { 
  description = "Train Task Memory"
  type = number 
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}


variable "alb_target_port" {
  description = "Port that ALB forwards to on container"
  type        = number

}

variable "alb_listener_port" {
  description = "Port that the ALB listens on (HTTPS)"
  type        = number
}
