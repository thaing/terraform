output "role_arn" {
  description = "ARN of the project IAM role"
  value       = aws_iam_role.project.arn
}

output "role_name" {
  description = "Name of the project IAM role"
  value       = aws_iam_role.project.name
}

output "policy_arn" {
  description = "ARN of the project IAM policy"
  value       = aws_iam_policy.project.arn
}
