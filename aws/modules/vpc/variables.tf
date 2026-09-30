variable "project" {
  description = "Project name used for VPC naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name used for VPC naming and tagging"
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid IPv4 CIDR notation, e.g. 10.0.0.0/16."
  }
}

variable "tags" {
  description = "Additional tags to apply to VPC resources"
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "Availability zones used for public and private subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
