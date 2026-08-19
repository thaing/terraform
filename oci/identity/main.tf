provider "oci" {
  region              = var.region
  auth                = "ConfigFile"
  config_file_profile = "DEFAULT"
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

module "iam" {
  source     = "../modules/iam"
  project    = var.project
  tenancy_id = var.tenancy_id
  tags       = local.common_tags
}
