output "budget_id" {
  description = "OCID of the budget"
  value       = oci_budget_budget.cost.id
}

output "alert_rule_id" {
  description = "OCID of the budget alert rule"
  value       = oci_budget_alert_rule.forecast.id
}
