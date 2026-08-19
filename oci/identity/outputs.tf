output "compartment_id" {
  description = "OCID of the project compartment"
  value       = module.iam.compartment_id
}

output "group_name" {
  description = "Name of the project IAM group"
  value       = module.iam.group_name
}

output "policy_id" {
  description = "OCID of the project IAM policy"
  value       = module.iam.policy_id
}
