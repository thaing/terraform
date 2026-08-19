terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 8.0"
    }
  }
}

resource "oci_objectstorage_bucket" "state" {
  compartment_id = var.compartment_id
  name           = var.name
  namespace      = var.namespace
  versioning     = "Enabled"
  freeform_tags  = var.tags

  lifecycle {
    prevent_destroy = true
  }
}
