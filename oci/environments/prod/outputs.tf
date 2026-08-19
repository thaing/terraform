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

output "instance_id" {
  description = "OCID of the compute instance"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the compute instance"
  value       = module.compute.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the compute instance"
  value       = module.compute.private_ip
}

output "storage_bucket_id" {
  description = "OCID of the Object Storage bucket"
  value       = module.storage.bucket_id
}

output "storage_bucket_name" {
  description = "Name of the Object Storage bucket"
  value       = module.storage.bucket_name
}

output "storage_namespace" {
  description = "Object Storage namespace"
  value       = module.storage.namespace
}
