output "state_bucket_names" {
  description = "Map of environment name to state bucket name"
  value       = { for k, v in module.state_bucket : k => v.bucket_name }
}

output "state_bucket_ids" {
  description = "Map of environment name to state bucket ID"
  value       = { for k, v in module.state_bucket : k => v.bucket_id }
}
