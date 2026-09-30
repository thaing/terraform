output "state_bucket_name" {
  description = "Shared state bucket name"
  value       = module.state_bucket.s3_bucket_id
}

output "state_bucket_arn" {
  description = "Shared state bucket ARN"
  value       = module.state_bucket.s3_bucket_arn
}

output "state_bucket_version_status" {
  description = "Shared state bucket version status"
  value       = module.state_bucket.aws_s3_bucket_versioning_status
}
