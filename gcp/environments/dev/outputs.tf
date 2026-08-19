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