output "public_subnet_id" {
  description = "ID of the public subnet (hosts compute instances, Phase 4)"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet (local-only routing, future secure resources)"
  value       = module.networking.private_subnet_id
}

output "network_id" {
  description = "ID of the VCN"
  value       = module.networking.network_id
}

output "security_list_ids" {
  description = "IDs of the security lists attached to the public subnet"
  value       = module.networking.security_list_ids
}
