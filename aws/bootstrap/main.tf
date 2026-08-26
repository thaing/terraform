provider "aws" {
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

  name = "${var.project}-aws-state"
  tags = local.common_tags
}
