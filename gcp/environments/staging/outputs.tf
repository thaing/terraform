output "public_subnet_id" {
  description = "ID of the public subnetwork (hosts compute instances, Phase 4)"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnetwork (no external IPs, Phase 4)"
  value       = module.networking.private_subnet_id
}

output "network_id" {
  description = "ID of the VPC network"
  value       = module.networking.network_id
}

output "firewall_rule_names" {
  description = "Names of the four ingress firewall rules (ssh, http, https, icmp)"
  value       = module.networking.firewall_rule_names
}

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

output "storage_bucket_id" {
  description = "ID of the GCS storage bucket"
  value       = module.storage.bucket_id
}

output "storage_bucket_name" {
  description = "Name of the GCS storage bucket"
  value       = module.storage.bucket_name
}

output "storage_bucket_url" {
  description = "URL of the GCS storage bucket"
  value       = module.storage.bucket_url
}

output "cluster_id" {
  description = "GKE cluster ID"
  value       = module.kubernetes.cluster_id
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.kubernetes.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = module.kubernetes.cluster_ca_certificate
  sensitive   = true
}

output "node_pool_names" {
  description = "GKE node pool names"
  value       = module.kubernetes.node_pool_names
}