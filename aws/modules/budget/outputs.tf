output "budget_id" {
  description = "ID (name) of the AWS budget"
  value       = var.create_budget ? aws_budgets_budget.cost[0].id : null
}

output "budget_arn" {
  description = "ARN of the AWS budget"
  value       = var.create_budget ? aws_budgets_budget.cost[0].arn : null
}
