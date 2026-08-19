provider "oci" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

module "networking" {
  source              = "../../modules/networking"
  project             = var.project
  environment         = var.environment
  cidr_block          = var.cidr_block
  ssh_source_cidr     = var.ssh_source_cidr
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  tags                = local.common_tags
}
