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
  description = "CIDR block for the VPC (10.1.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid IPv4 CIDR notation, e.g. 10.1.0.0/16."
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

variable "gcp_project_id" {
  description = "GCP project ID hosting the VPC (the Google provider's `project` argument)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{5,29}$", var.gcp_project_id))
    error_message = "gcp_project_id must be a valid GCP project ID: 6-30 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format. Format for GCP: 'user@host:ssh-rsa AAAA...' (username prefix required by GCP metadata.ssh-keys)"
  type        = string
}

variable "image" {
  description = "GCP image family or full image URL. Default: debian-12"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "storage_bucket_name" {
  description = "GCS bucket name. Must be 3-63 lowercase alphanumeric, dots, hyphens. Pattern: multicloud-tf-{env}-gcp-storage"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9.-]{1,61}[a-z0-9]$", var.storage_bucket_name))
    error_message = "storage_bucket_name must be 3-63 lowercase alphanumeric, dots, or hyphens."
  }
}

variable "size" {
  description = "Instance machine type (e.g. e2-micro for GCP free tier)"
  type        = string
  default     = "e2-micro"
}
