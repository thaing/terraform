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
