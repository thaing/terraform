locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  create = true

  use_name_prefix = false
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = var.name
    },
    local.common_tags
  )

  # Ingress rules
  ingress_rules = var.ingress_rules

  # Egress rules
  egress_rules = var.egress_rules
}
