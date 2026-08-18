output "state_bucket_names" {
  description = "Map of environment name to state bucket name"
  value       = { for k, v in module.state_bucket : k => v.bucket_name }
}

output "state_bucket_urls" {
  description = "Map of environment name to state bucket URL"
  value       = { for k, v in module.state_bucket : k => v.bucket_url }
}
