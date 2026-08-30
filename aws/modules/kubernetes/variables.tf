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

variable "size" {
  description = "Kubernetes node pool size tier (maps to instance types per D-41)"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "vpc_id" {
  description = "ID of the VPC the EKS cluster runs in (from the networking module)"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for the EKS cluster and node group (EKS requires subnets in at least 2 AZs — B1, both public subnets)"
  type        = list(string)
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (ssh-rsa AAAA... user@host)"
  type        = string
}

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
}

variable "k8s_version" {
  description = "EKS Kubernetes version. Pinned to 1.36 (latest standard-support) to avoid the extended-support cost cliff per D-35"
  type        = string
  default     = "1.36"
}