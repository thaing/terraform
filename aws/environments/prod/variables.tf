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
  description = "CIDR block for the VPC (10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid IPv4 CIDR notation, e.g. 10.0.0.0/16."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH (port 22). Set to your public IP /32. REQUIRED — never 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be valid IPv4 CIDR notation, e.g. 203.0.113.7/32."
  }
}

variable "availability_zone" {
  description = "AWS availability zone for subnets (single AZ per D-20)"
  type        = string
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (ssh-rsa AAAA... user@host). REQUIRED — never leave empty."
  type        = string
}

variable "storage_bucket_name" {
  description = "Globally unique S3 bucket name. Must be 3-63 lowercase alphanumeric, dots, hyphens. Pattern: multicloud-tf-{env}-aws-storage"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9.-]{1,61}[a-z0-9]$", var.storage_bucket_name))
    error_message = "Bucket name must start and end with lowercase alphanumeric, contain only lowercase alphanumeric, dots, and hyphens, and be 3-63 characters."
  }
}

variable "size" {
  description = "Instance type (e.g. t3.micro for AWS free tier)"
  type        = string
  default     = "t3.micro"
}

variable "image_id" {
  description = "AMI ID override. When null, uses latest Ubuntu 22.04 from Canonical via data source (per D-28)"
  type        = string
  default     = null
}

variable "cost_alert_amount" {
  description = "Dollar amount (USD) of the monthly cost budget. Alerts when forecasted spend is projected to exceed this."
  type        = number
  default     = 10
}

variable "alert_email" {
  description = "Email address that receives cost-budget alerts"
  type        = string
}

variable "size_k8s" {
  description = "Kubernetes node pool size tier. Mapped via kubernetes module locals (small=t3.micro spot, medium=t4g.medium, large=m6i.large). Per D-41/D-42."
  type        = string
  default     = "small"
}

variable "availability_zone_b" {
  description = "AWS availability zone for the second public subnet (EKS requires subnets in ≥ 2 AZs — B1). Must differ from availability_zone."
  type        = string
}

variable "k8s_version" {
  description = "EKS Kubernetes version. Pinned to 1.36 (latest standard-support) to avoid the extended-support cost cliff per D-35"
  type        = string
  default     = "1.36"
}
