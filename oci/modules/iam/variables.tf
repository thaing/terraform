variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.project))
    error_message = "Project must start with a lowercase letter, contain only lowercase alphanumeric and hyphens, and be at most 31 characters."
  }
}

variable "tenancy_id" {
  description = "OCI tenancy OCID (root compartment) — parent of the created project compartment (D-24)"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
