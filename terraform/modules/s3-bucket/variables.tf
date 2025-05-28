variable "bucket_name" {
  description = "Exact name of the S3 bucket"
  type        = string
}
variable "environment" {
  description = "Deployment environment (dev/test/prod)"
  type        = string
}
variable "versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "ingress_security_groups" {
  description = "List of security group IDs allowed to ingress"
  type        = list(string)
  default     = []
}