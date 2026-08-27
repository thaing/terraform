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

variable "region" {
  description = "Cloud provider region for resource deployment"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VCN (10.2.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid IPv4 CIDR notation, e.g. 10.0.0.0/16."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH (port 22). REQUIRED — never 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be valid IPv4 CIDR notation, e.g. 203.0.113.7/32."
  }
}

variable "availability_domain" {
  description = "OCI availability domain for subnets (single AD per D-20)"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID for the VCN (project compartment from oci/identity/ apply, or root compartment during config-only)"
  type        = string
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (ssh-rsa AAAA... user@host). REQUIRED — never leave empty."
  type        = string
}

variable "storage_bucket_name" {
  description = "OCI Object Storage bucket name. Must be 3-63 lowercase alphanumeric, dots, hyphens. Pattern: multicloud-tf-{env}-oci-storage"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9.-]{1,61}[a-z0-9]$", var.storage_bucket_name))
    error_message = "Bucket name must start and end with lowercase alphanumeric, contain only lowercase alphanumeric, dots, and hyphens, and be 3-63 characters."
  }
}

variable "size" {
  description = "Instance size tier (per D-27: only small creates resources)"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "image_id" {
  description = "OCI platform image OCID for the compute instance (Ubuntu 22.04 for your region)"
  type        = string
}

variable "shape" {
  description = "OCI compute shape for the instance. Default: VM.Standard.A1.Flex (Always Free ARM flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}
