variable "name" {
  description = "Name of the OCI Object Storage bucket for remote state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{0,61}[a-z0-9]$", var.name))
    error_message = "Bucket name must start and end with a lowercase alphanumeric character and contain only lowercase letters, digits, dots, dashes, and underscores (1-63 characters)."
  }
}

variable "namespace" {
  description = "OCI Object Storage namespace (from `oci os ns get`)"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID where the bucket lives"
  type        = string
}

variable "tags" {
  description = "Freeform tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
