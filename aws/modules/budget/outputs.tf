output "budget_id" {
  description = "ID (name) of the AWS budget"
  value       = aws_budgets_budget.cost.id
}

output "budget_arn" {
  description = "ARN of the AWS budget"
  value       = aws_budgets_budget.cost.arn
}
