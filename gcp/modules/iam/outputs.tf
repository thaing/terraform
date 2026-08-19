output "service_account_email" {
  description = "Email address of the project service account"
  value       = google_service_account.project.email
}

output "service_account_id" {
  description = "ID of the project service account"
  value       = google_service_account.project.id
}

output "service_account_member" {
  description = "Member identity of the service account (serviceAccount:<email>)"
  value       = google_service_account.project.member
}
