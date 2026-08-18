variable "name" {
  description = "Globally unique name of the GCS bucket for remote state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.name))
    error_message = "Bucket name must start and end with a lowercase alphanumeric character and contain only lowercase letters, digits, dots, dashes, and underscores (3-63 characters)."
  }
}

variable "location" {
  description = "GCS bucket location (region)"
  type        = string
}

variable "tags" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}
