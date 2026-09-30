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

variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "Tags to apply to the security group"
  type        = map(string)
  default     = {}
}

# Ingress rules with CIDR blocks
variable "ingress_rules" {
  description = "List of ingress rules"
  type = map(object({ 
    name = optional(string) 
    cidr_ipv4 = optional(string) 
    cidr_ipv6 = optional(string) 
    description = optional(string) 
    from_port = optional(number) 
    ip_protocol = optional(string, "tcp") 
    prefix_list_id = optional(string) 
    referenced_security_group_id = optional(string) 
    tags = optional(map(string), {}) 
    to_port = optional(number) 
  }))
  default = {}
}

# Egress rules
variable "egress_rules" {
  description = "Map of egress rules"
  type = map(object({ 
    name = optional(string) 
    cidr_ipv4 = optional(string) 
    cidr_ipv6 = optional(string) 
    description = optional(string) 
    from_port = optional(number) 
    ip_protocol = optional(string, "tcp") 
    prefix_list_id = optional(string) 
    referenced_security_group_id = optional(string) 
    tags = optional(map(string), {}) 
    to_port = optional(number) 
  }))
  default = {
    air_gap = {
      description  = "Disallow all outbound traffic"
      ip_protocol = "-1"
      cidr_ipv4   = "127.0.0.0/32"
    }
  }
}
