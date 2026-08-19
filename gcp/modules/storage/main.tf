locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

resource "google_storage_bucket" "storage" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = false

  # D-29: Versioning enabled (inline block for GCP)
  versioning {
    enabled = true
  }

  # D-33: Uniform bucket-level access (IAM-gated only)
  uniform_bucket_level_access = true

  labels = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
