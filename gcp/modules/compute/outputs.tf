output "instance_id" {
  description = "ID of the compute instance"
  value       = google_compute_instance.main.id
}

output "public_ip" {
  description = "Public IP of the compute instance (null when public_ip = false)"
  value       = var.public_ip ? google_compute_instance.main.network_interface[0].access_config[0].nat_ip : null
}

output "private_ip" {
  description = "Private IP of the compute instance"
  value       = google_compute_instance.main.network_interface[0].network_ip
}
