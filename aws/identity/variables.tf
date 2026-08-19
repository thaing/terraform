variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.project))
    error_message = "Project must start with a lowercase letter, contain only lowercase alphanumeric and hyphens, and be at most 31 characters."
  }
}

variable "region" {
  description = "AWS region for the IAM provider (IAM is global; region only satisfies the provider)"
  type        = string
}

variable "trust_principal" {
  description = "ARN of the user/CI principal allowed to assume the project role (D-25)"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}
