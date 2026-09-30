locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

# Monthly cost budget whose alert fires when FORECASTED spend is projected to
# exceed the dollar amount (var.cost_alert_amount). Notifies var.alert_email.
resource "aws_budgets_budget" "cost" {
  count        = var.create_budget ? 1 : 0
  name         = var.budget_name
  budget_type  = "COST"
  limit_amount = tostring(var.cost_alert_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = local.common_tags

  dynamic "cost_filter" {
    for_each = var.cost_filter == null ? [] : [var.cost_filter]

    content {
      name   = cost_filter.value.name
      values = cost_filter.value.values
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.cost_alert_amount
    threshold_type             = "ABSOLUTE_VALUE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
