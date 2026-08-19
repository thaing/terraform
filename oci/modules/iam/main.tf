locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

resource "oci_identity_compartment" "project" {
  compartment_id = var.tenancy_id
  name           = "${var.project}-oci"
  description    = "Project compartment (IAM boundary, one per cloud per D-24)"
  freeform_tags  = local.common_tags
}

resource "oci_identity_group" "project" {
  name          = "${var.project}-oci-group"
  description   = "Project IAM group (created this phase per D-26)"
  freeform_tags = local.common_tags
}

resource "oci_identity_policy" "project" {
  compartment_id = oci_identity_compartment.project.id
  name           = "${var.project}-oci-policy"
  description    = "Least-privilege project access (D-23)"
  statements = [
    "Allow group ${oci_identity_group.project.name} to manage virtual-network-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.project.name} to use instance-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.project.name} to manage volume-family in compartment ${oci_identity_compartment.project.name}",
    "Allow group ${oci_identity_group.project.name} to manage object-family in compartment ${oci_identity_compartment.project.name}",
  ]
}
