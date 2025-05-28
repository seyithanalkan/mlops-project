variable "environment" {
  description = "Deployment environment (dev/test/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where SG will be created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the security group name"
  type        = string
}

variable "ingress" {
  description = "List of CIDR-based ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "ingress_security_groups" {
  description = "List of security group IDs allowed ingress"
  type        = list(string)
  default     = []
}

variable "egress" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}
