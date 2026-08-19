provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

module "iam" {
  source          = "../modules/iam"
  project         = var.project
  trust_principal = var.trust_principal
  tags            = local.common_tags
}
