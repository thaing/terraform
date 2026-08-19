variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.project))
    error_message = "Project must start with a lowercase letter, contain only lowercase alphanumeric and hyphens, and be at most 31 characters."
  }
}

variable "environment" {
  description = "Deployment environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}

variable "size" {
  description = "Instance size tier"
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "subnet_id" {
  description = "Subnet/network where the instance is placed"
  type        = string
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (ssh-rsa AAAA... user@host)"
  type        = string
}

variable "image_id" {
  description = "OCI platform image OCID for the compute instance (Ubuntu 22.04 for the configured region)"
  type        = string
}

variable "availability_domain" {
  description = "OCI availability domain for the instance"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID for the instance"
  type        = string
}
