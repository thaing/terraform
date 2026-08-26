output "state_bucket_name" {
  description = "Shared state bucket name"
  value       = module.state_bucket.bucket_name
}

output "state_bucket_arn" {
  description = "Shared state bucket ARN"
  value       = module.state_bucket.bucket_arn
}
