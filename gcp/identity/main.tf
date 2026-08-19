provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

module "iam" {
  source         = "../modules/iam"
  project        = var.project
  gcp_project_id = var.gcp_project_id
  tags           = local.common_tags
}
