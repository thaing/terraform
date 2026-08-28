locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  }
}

# Monthly cost budget scoped to the project compartment. Its alert rule fires
# on FORECAST spend exceeding the dollar amount (var.cost_alert_amount) and
# notifies var.alert_email.
resource "oci_budget_budget" "cost" {
  compartment_id = var.compartment_id
  display_name   = "${var.project}-${var.environment}-budget"
  amount         = var.cost_alert_amount
  reset_period   = "MONTHLY"
  target_type    = "COMPARTMENT"
  targets        = [var.compartment_id]
  freeform_tags  = local.common_tags
}

resource "oci_budget_alert_rule" "forecast" {
  budget_id      = oci_budget_budget.cost.id
  display_name   = "${var.project}-${var.environment}-forecast"
  type           = "FORECAST"
  threshold      = var.cost_alert_amount
  threshold_type = "ABSOLUTE"
  recipients     = var.alert_email
  freeform_tags  = local.common_tags
}
