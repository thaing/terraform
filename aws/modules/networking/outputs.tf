output "public_subnet_id" {
  description = "ID of the public subnet (hosts compute instances, Phase 4)"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet (local-only routing, future secure resources)"
  value       = aws_subnet.private.id
}

output "network_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public.id
}

output "public_subnet_id_b" {
  description = "ID of the second public subnet (AZ b — EKS requires subnets in ≥ 2 AZs, B1)"
  value       = aws_subnet.public_b.id
}

output "public_subnet_ids" {
  description = "IDs of both public subnets (feed to EKS vpc_config / node group)"
  value       = [aws_subnet.public.id, aws_subnet.public_b.id]
}
