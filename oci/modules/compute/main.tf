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

  # Second volume is created only when size > 0
  create_second_volume = var.second_volume_size_gb > 0

  # Cloud-init user_data for mounting second volume
  user_data = local.create_second_volume ? base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
    device_name = var.second_volume_device_name
    mount_point = var.second_volume_mount_point
  })) : null
}

resource "oci_core_instance" "main" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project}-${var.environment}-instance"
  shape               = var.shape

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
    "user_data"           = local.user_data
  }

  freeform_tags = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

# Second block volume (optional) - OCI Always Free tier includes 200 GB total
# prevent_destroy = true ensures volume persists if instance is terminated from console
resource "oci_core_volume" "second" {
  count               = local.create_second_volume ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.project}-${var.environment}-volume-2"
  size_in_gbs         = var.second_volume_size_gb
  freeform_tags       = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Attach second volume to instance
resource "oci_core_volume_attachment" "second" {
  count           = local.create_second_volume ? 1 : 0
  instance_id     = oci_core_instance.main.id
  volume_id       = oci_core_volume.second[0].id
  attachment_type = "paravirtualized"
  display_name    = "${var.project}-${var.environment}-volume-2-attachment"
}
