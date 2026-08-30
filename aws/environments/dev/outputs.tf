output "public_subnet_id" {
  description = "ID of the public subnet (hosts compute instances, Phase 4)"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet (local-only routing, future secure resources)"
  value       = module.networking.private_subnet_id
}

output "network_id" {
  description = "ID of the VPC"
  value       = module.networking.network_id
}

output "security_group_id" {
  description = "ID of the public security group"
  value       = module.networking.security_group_id
}

# Compute outputs
output "instance_id" {
  description = "ID of the compute instance"
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

# Storage outputs
output "storage_bucket_id" {
  description = "ID of the S3 storage bucket"
  value       = module.storage.bucket_id
}

output "storage_bucket_name" {
  description = "Name of the S3 storage bucket"
  value       = module.storage.bucket_name
}

output "storage_bucket_arn" {
  description = "ARN of the S3 storage bucket"
  value       = module.storage.bucket_arn
}

# EKS cluster outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.kubernetes.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.kubernetes.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.kubernetes.cluster_ca_certificate
  sensitive   = true
}

output "node_pool_names" {
  description = "EKS node pool names"
  value       = module.kubernetes.node_pool_names
}
