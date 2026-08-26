provider "oci" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

module "state_bucket" {
  source = "./modules/state_bucket"

  name           = "${var.project}-oci-state"
  namespace      = var.namespace
  compartment_id = var.compartment_id
  tags           = local.common_tags
}
