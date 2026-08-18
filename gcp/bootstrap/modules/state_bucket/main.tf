resource "google_storage_bucket" "state" {
  name     = var.name
  location = var.location

  uniform_bucket_level_access = true
  labels                      = var.tags

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
