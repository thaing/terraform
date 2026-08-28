locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

resource "google_compute_instance" "main" {
  name         = "${var.project}-${var.environment}-instance"
  machine_type = var.size
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = var.image # D-28: Default debian-cloud/debian-12
    }
  }

  network_interface {
    subnetwork = var.subnet_id

    dynamic "access_config" {
      # Ephemeral public IP — D-31 (conditional; default true to match AWS/OCI)
      for_each = var.public_ip ? [1] : []
      content {
      }
    }
  }

  # D-32: SSH key via metadata
  metadata = {
    "ssh-keys" = var.public_key_openssh
  }

  labels = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
