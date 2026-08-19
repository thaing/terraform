output "service_account_email" {
  description = "Email address of the project service account"
  value       = module.iam.service_account_email
}

output "service_account_id" {
  description = "ID of the project service account"
  value       = module.iam.service_account_id
}

output "service_account_member" {
  description = "Member identity of the service account (serviceAccount:<email>)"
  value       = module.iam.service_account_member
}
