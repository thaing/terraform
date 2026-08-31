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
  description = "Kubernetes node pool size tier. Mapped to node_shape_config (small/medium=1 OCPU/6GB ARM, large=2 OCPU/12GB ARM) within the OCI Always Free 2/12 cap"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Size must be one of: small, medium, large."
  }
}

variable "vcn_id" {
  description = "OCID of the VCN the OKE cluster integrates with (from the networking module network_id output)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet OCIDs: [0]=public (cluster endpoint), [1]=private (node pool; OCI forbids node pools on the endpoint/service subnet)"
  type        = list(string)
}

variable "compartment_id" {
  description = "OCI compartment OCID for the OKE cluster and node pool"
  type        = string
}

variable "availability_domain" {
  description = "OCI availability domain for the single node pool placement (required by the provider; the underlying subnet is regional)"
  type        = string
}

variable "public_key_openssh" {
  description = "Public SSH key in OpenSSH format (ssh-rsa AAAA... user@host). Injected on OKE nodes for optional SSH access (D-52 parity)"
  type        = string
}

variable "node_shape" {
  description = "OCI compute shape for node pool. Use VM.Standard.A1.Flex for ARM Always Free (2 OCPU/12 GB cap) or VM.Standard.E2.1 for x86 Always Free (2×1 OCPU/1 GB). Paid shapes also allowed."
  type        = string
  default     = "VM.Standard.E2.1"

  validation {
    condition     = contains(["VM.Standard.A1.Flex", "VM.Standard.E2.1", "VM.Standard.E2.2", "VM.Standard.E2.4", "VM.Standard.E2.8", "VM.Standard.E3.Flex", "VM.Standard.E4.Flex", "VM.Standard.E5.Flex", "VM.Standard.E6.Flex"], var.node_shape)
    error_message = "Unsupported node_shape. Choose from ARM Always Free (VM.Standard.A1.Flex), x86 Always Free (VM.Standard.E2.1), or common paid Flex/E2 shapes."
  }
}

variable "k8s_version" {
  description = "OKE Kubernetes version. Leave default to use v1.34.10 (latest v1.34 patch), or pin to a current stable version per OKE docs."
  type        = string
  default     = "v1.34.10"
}