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
  description = "Kubernetes node pool size tier (maps to GKE machine types per D-41). small=e2-micro (free in US regions), medium=e2-standard-2, large=e2-standard-4."
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "network" {
  description = "ID/self_link of the VPC network (from networking module network_id)"
  type        = string
}

variable "subnetwork" {
  description = "Self_link of the public subnetwork (from networking module public_subnet_id)"
  type        = string
}

variable "secondary_pod_range_name" {
  description = "Name of the pod secondary_ip_range on the public subnetwork (VPC-native / Dataplane V2, B2)"
  type        = string
}

variable "secondary_service_range_name" {
  description = "Name of the service secondary_ip_range on the public subnetwork (VPC-native / Dataplane V2, B2)"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID — used for workload_identity_config workload pool"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
}

variable "zone" {
  description = "GCP zone for the node pool, e.g. us-central1-a"
  type        = string
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (accepted for interface parity per D-52; GKE manages node SSH via service account, so this is not applied to GKE nodes directly)"
  type        = string
}

variable "k8s_version" {
  description = "GKE cluster version. GKE uses release channels; prefer leaving the default to let GKE manage minor upgrades within the channel."
  type        = string
  default     = "1.36"
}
