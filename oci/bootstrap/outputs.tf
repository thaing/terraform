output "state_bucket_name" {
  description = "Shared state bucket name"
  value       = module.state_bucket.bucket_name
}

output "state_bucket_id" {
  description = "Shared state bucket ID"
  value       = module.state_bucket.bucket_id
}
