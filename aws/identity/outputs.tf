output "role_arn" {
  description = "ARN of the project IAM role"
  value       = module.iam.role_arn
}

output "role_name" {
  description = "Name of the project IAM role"
  value       = module.iam.role_name
}

output "policy_arn" {
  description = "ARN of the project IAM policy"
  value       = module.iam.policy_arn
}
