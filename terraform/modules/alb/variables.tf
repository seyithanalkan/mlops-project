variable "environment" {
  description = "dev/test/prod"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Group IDs for the ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "listener_port" {
  description = "Load balancer listener port"
  type        = number
  default     = 443
}

variable "target_port" {
  description = "Port on the containers that the ALB forwards to"
  type        = number
}
