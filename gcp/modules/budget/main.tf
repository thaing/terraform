data "google_project" "budget" {}

# Email notification channel that delivers billing-budget alerts.
resource "google_monitoring_notification_channel" "alert" {
  display_name = "${var.project}-${var.environment}-budget-alert"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# Monthly cost budget whose threshold alerts on FORECASTED spend reaching
# the dollar amount (var.cost_alert_amount). Scoped to the current project.
resource "google_billing_budget" "cost" {
  billing_account = var.billing_account_id
  display_name    = "${var.project}-${var.environment}-budget"

  budget_filter {
    projects = ["projects/${data.google_project.budget.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.cost_alert_amount)
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.alert.id]
    disable_default_iam_recipients   = true
  }
}
