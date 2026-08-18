variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.project))
    error_message = "Project must start with a lowercase letter, contain only lowercase alphanumeric and hyphens, and be at most 31 characters."
  }
}

variable "environments" {
  description = "Environments to provision state buckets for"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "gcp_project_id" {
  description = "GCP project ID appended to bucket names for global uniqueness (RESEARCH Pitfall 4)"
  type        = string
}

variable "region" {
  description = "GCP region for state buckets"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
