output "state_bucket_name" {
  description = "Shared state bucket name"
  value       = module.state_bucket.bucket_name
}

output "state_bucket_url" {
  description = "Shared state bucket URL"
  value       = module.state_bucket.bucket_url
}
