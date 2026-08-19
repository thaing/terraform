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

variable "bucket_name" {
  description = "Name of the storage bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with lowercase alphanumeric, contain only lowercase alphanumeric, dots, and hyphens, and be 3-63 characters."
  }
}

variable "region" {
  description = "GCP region for bucket location"
  type        = string
}
