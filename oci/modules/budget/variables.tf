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

variable "compartment_id" {
  description = "OCID of the compartment whose spend the budget tracks (the project compartment)"
  type        = string
}

variable "tenancy_id" {
  description = "OCI tenancy OCID (root compartment) where the budget resource resides"
  type        = string
}

variable "cost_alert_amount" {
  description = "Dollar amount (USD) of the monthly cost budget. Alerts when forecast spend is projected to exceed this."
  type        = number

  validation {
    condition     = var.cost_alert_amount > 0
    error_message = "cost_alert_amount must be a positive dollar amount."
  }
}

variable "alert_email" {
  description = "Email address that receives cost-budget alerts"
  type        = string
}
