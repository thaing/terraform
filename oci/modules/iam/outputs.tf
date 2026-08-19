output "compartment_id" {
  description = "OCID of the project compartment (IAM boundary)"
  value       = oci_identity_compartment.project.id
}

output "group_name" {
  description = "Name of the project IAM group"
  value       = oci_identity_group.project.name
}

output "policy_id" {
  description = "OCID of the project IAM policy"
  value       = oci_identity_policy.project.id
}
