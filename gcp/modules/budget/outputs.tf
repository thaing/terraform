output "budget_id" {
  description = "Resource name of the billing budget"
  value       = google_billing_budget.cost.id
}

output "notification_channel_id" {
  description = "Resource name of the email notification channel"
  value       = google_monitoring_notification_channel.alert.id
}

output "notification_channel_name" {
  description = "Name of the email notification channel"
  value       = google_monitoring_notification_channel.alert.name
}
