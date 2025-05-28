variable "vpc_name" {
  type        = string
  description = "Prefix for all VPC resources"
}

variable "cidr_block" {
  type        = string
  description = "The main VPC CIDR block"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs for subnet spread"
}

variable "subnet_bits" {
  type        = number
  description = "Number of additional bits for each subnet mask"
  default     = 8
}
