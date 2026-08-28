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

variable "billing_account_id" {
  description = "Cloud Billing account ID (XXXXXX-XXXXXX-XXXXXX) the budget attaches to. Budgets are per billing account, not per project."
  type        = string
}

variable "cost_alert_amount" {
  description = "Dollar amount (USD) of the monthly cost budget. Alerts when forecasted spend is projected to exceed this."
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
