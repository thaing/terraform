locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  public_subnet_cidr  = cidrsubnet(var.cidr_block, 8, 0) # 10.1.0.0/24
  private_subnet_cidr = cidrsubnet(var.cidr_block, 8, 1) # 10.1.1.0/24

  # B2: VPC-native secondary ranges for GKE Dataplane V2 (pods + services).
  # Index 0 is skipped because it contains the primary public 10.1.0.0/24 +
  # private 10.1.1.0/24 ranges. Indexes 1 and 2 are guaranteed non-overlapping and
  # aligned to the /18 boundary (GCP rejects unaligned secondary ranges — do NOT
  # hardcode "10.1.2.0/18", which is not /18-aligned).
  pod_secondary_cidr     = cidrsubnet(var.cidr_block, 2, 1) # 10.1.64.0/18 under the 10.1.0.0/16 scheme
  service_secondary_cidr = cidrsubnet(var.cidr_block, 2, 2) # 10.1.128.0/18
}

# Custom-mode VPC: auto_create_subnetworks = false disables the auto-mode subnets
# so D-22's 10.1.0.0/16 CIDR scheme applies (auto-mode would force 10.128.0.0/9).
# GCP injects a system-generated 0.0.0.0/0 -> default internet gateway route, so
# there is NO internet-gateway or route-table resource to declare (unlike AWS/OCI).
resource "google_compute_network" "main" {
  name                    = "${var.project}-${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.project}-${var.environment}-public"
  ip_cidr_range = local.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id

  # B2: VPC-native secondary ranges — GKE Dataplane V2 (ADVANCED_DATAPATH) is
  # VPC-native and rejects clusters without these secondary ranges at apply.
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = local.pod_secondary_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = local.service_secondary_cidr
  }
}

# GCP subnetworks have no public/private attribute. The "private" subnetwork is a
# second CIDR range; its privateness is realized in Phase 4 when instances are
# placed here WITHOUT external IPs.
resource "google_compute_subnetwork" "private" {
  name          = "${var.project}-${var.environment}-private"
  ip_cidr_range = local.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

# A custom-mode VPC ships with NO pre-populated firewall rules, so all four
# ingress rules must be declared explicitly. Egress is implied-allow (no rule).
resource "google_compute_firewall" "ssh" {
  name    = "${var.project}-${var.environment}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]
}

resource "google_compute_firewall" "http" {
  name    = "${var.project}-${var.environment}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "https" {
  name    = "${var.project}-${var.environment}-allow-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "icmp" {
  name    = "${var.project}-${var.environment}-allow-icmp"
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}
