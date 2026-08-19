output "state_bucket_name" {
  description = "State bucket name for the environment"
  value       = module.state_bucket.bucket_name
}

output "state_bucket_url" {
  description = "State bucket URL for the environment"
  value       = module.state_bucket.bucket_url
}
