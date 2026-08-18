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

module "state_bucket" {
  source   = "./modules/state_bucket"
  for_each = toset(var.environments)

  name     = "${var.project}-${each.key}-gcp-state-${var.gcp_project_id}"
  location = var.region
  tags     = merge(local.common_tags, { environment = each.key })
}
