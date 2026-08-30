output "public_subnet_id" {
  description = "ID of the public subnetwork (hosts compute instances, Phase 4)"
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnetwork (no external IPs, Phase 4)"
  value       = google_compute_subnetwork.private.id
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "firewall_rule_names" {
  description = "Names of the four ingress firewall rules (ssh, http, https, icmp)"
  value = [
    google_compute_firewall.ssh.name,
    google_compute_firewall.http.name,
    google_compute_firewall.https.name,
    google_compute_firewall.icmp.name,
  ]
}

output "secondary_pod_cidr" {
  description = "Secondary CIDR for GKE pod IPs (VPC-native / Dataplane V2, B2)"
  value       = local.pod_secondary_cidr
}

output "secondary_pod_range_name" {
  description = "Name of the pod secondary_ip_range on the public subnetwork"
  value       = "pods"
}

output "secondary_service_cidr" {
  description = "Secondary CIDR for GKE service IPs (VPC-native / Dataplane V2, B2)"
  value       = local.service_secondary_cidr
}

output "secondary_service_range_name" {
  description = "Name of the service secondary_ip_range on the public subnetwork"
  value       = "services"
}
