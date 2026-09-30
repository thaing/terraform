variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.project))
    error_message = "Project must start with a lowercase letter, contain only lowercase alphanumeric and hyphens, and be at most 31 characters."
  }
}

# variable "environment" {
#   description = "Deployment environment name"
#   type        = string

#   validation {
#     condition     = contains(["dev", "staging", "prod"], var.environment)
#     error_message = "Environment must be one of: dev, staging, prod."
#   }
# }

variable "tags" {
  description = "Additional tags to merge with default tags"
  type        = map(string)
  default     = {}
}

variable "budget_name" {
  description = "Budget name"
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

variable "create_budget" {
  description = "Whether to create the AWS cost budget"
  type        = bool
  default     = true
}

variable "cost_filter" {
  description = "Optional AWS Budgets cost dimension filter"
  type = object({
    name   = string
    values = list(string)
  })
  default = null

  validation {
    condition = var.cost_filter == null || (
      contains([
        "AZ",
        "BillingEntity",
        "CostCategory",
        "InstanceType",
        "InvoicingEntity",
        "LegalEntityName",
        "LinkedAccount",
        "Operation",
        "PurchaseType",
        "Region",
        "Service",
        "TagKeyValue",
        "UsageType",
        "UsageTypeGroup",
      ], var.cost_filter.name) &&
      trimspace(var.cost_filter.name) != "" &&
      length(var.cost_filter.values) > 0
    )
    error_message = "When set, cost_filter.name must be a valid AWS Budgets cost filter name and values must contain at least one value."
  }
}