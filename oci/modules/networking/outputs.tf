output "public_subnet_id" {
  description = "ID of the public subnet (hosts compute instances, Phase 4)"
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet (local-only routing, future secure resources)"
  value       = oci_core_subnet.private.id
}

output "network_id" {
  description = "ID of the VCN"
  value       = oci_core_vcn.main.id
}

output "security_list_ids" {
  description = "IDs of the security lists attached to the public subnet"
  value       = [oci_core_security_list.public.id]
}
