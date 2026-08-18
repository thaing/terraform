variable "name" {
  description = "Name of the S3 bucket used for remote state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.name))
    error_message = "Bucket name must start and end with a lowercase alphanumeric character and contain only lowercase letters, digits, dots, and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
