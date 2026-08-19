locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # D-27: Size mapping — only "small" creates resources (free-tier ARM flex shape)
  shape_config = {
    small  = { ocpus = 1, memory_in_gbs = 6 }
    medium = null
    large  = null
  }
}

resource "oci_core_instance" "main" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project}-${var.environment}-instance"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = local.shape_config[var.size].ocpus
    memory_in_gbs = local.shape_config[var.size].memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  # D-32: SSH key via metadata
  metadata = {
    "ssh_authorized_keys" = var.public_key_openssh
  }

  freeform_tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
