locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

# D-33: Namespace is tenancy-scoped — auto-detect via data source
data "oci_objectstorage_namespace" "current" {
  compartment_id = null
}

resource "oci_objectstorage_bucket" "storage" {
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = data.oci_objectstorage_namespace.current.namespace

  # D-29: Versioning enabled
  versioning = "Enabled"

  # D-33: No public access — IAM-gated only
  access_type = "NoPublicAccess"

  freeform_tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
