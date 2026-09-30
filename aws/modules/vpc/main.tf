locals {
  public_subnet_cidrs = [
    for index in range(length(var.availability_zones)) :
    cidrsubnet(var.cidr_block, 8, index)
  ]
  private_subnet_cidrs = [
    for index in range(length(var.availability_zones)) :
    cidrsubnet(var.cidr_block, 8, index + length(var.availability_zones))
  ]
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.cidr_block

  azs             = var.availability_zones
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = local.common_tags
}
