locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

# Monthly cost budget whose alert fires when FORECASTED spend is projected to
# exceed the dollar amount (var.cost_alert_amount). Notifies var.alert_email.
resource "aws_budgets_budget" "cost" {
  name         = "${var.project}-${var.environment}-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.cost_alert_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = local.common_tags

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.cost_alert_amount
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
