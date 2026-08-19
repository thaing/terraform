output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.main.id
}

output "public_ip" {
  description = "Public IP of the compute instance"
  value       = oci_core_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP of the compute instance"
  value       = oci_core_instance.main.private_ip
}
