# Hand-authored module (deliberate) — providers come from the registry, this module layer is
# hand-written per the project's core learning outcome (see research/ARCHITECTURE.md
# "Pattern: Hand-Authored Modules over Registry Modules").
# Production registry alternative: terraform-google-modules/kubernetes-engine
#   (https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine)
#   — opinionated GKE wrapper; prefer it for a production, non-learning project.
locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # D-41: size tier -> GKE machine type (dev smallest, staging/prod larger).
  # The small tier maps to GKE's smallest free-US-region instance (ASSUMED A3 —
  # may bump dev to e2-small/e2-medium if Cilium + nginx + metrics-server OOM in UAT).
  machine_types = {
    small  = "e2-micro"
    medium = "e2-standard-2"
    large  = "e2-standard-4"
  }
}

# GKE cluster auth token (access_token drives the helm/kubernetes providers + kubeconfig)
data "google_client_config" "current" {}

# --- GKE Standard cluster (D-34/D-36: managed GKE, free via $74.40/mo credit for one zonal cluster) ---
# Zonal (single-zone via var.zone) = only a zonal cluster is covered by the $74.40/mo credit
# (D-36). A REGIONAL cluster (3-zone control plane) would cost ~$223/mo and contradicts
# the free-tier cost-control constraint — hence location = var.zone, NOT var.region.
resource "google_container_cluster" "this" {
  name     = "${var.project}-${var.environment}-gke"
  location = var.zone
  project  = var.gcp_project_id

  # Cost control: avoid ephemeral default-pool churn (RESEARCH Implementation Notes)
  initial_node_count       = 1
  remove_default_node_pool = true

  network    = var.network
  subnetwork = var.subnetwork

  # D-53 / B2: Dataplane V2 (Cilium built-in) requires VPC-native networking —
  # pod/service IPs come from the networking module's secondary ranges (no separate
  # Cilium install on GKE).
  datapath_provider = "ADVANCED_DATAPATH"
  networking_mode   = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.secondary_pod_range_name
    services_secondary_range_name = var.secondary_service_range_name
  }

  # D-47: native GKE Workload Identity pool for pod -> GCP IAM mapping
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Minimal default node config (required even with the default pool removed).
  # COS_CONTAINERD image is implied by Dataplane V2 (eBPF); oauth_scopes limited
  # to cloud-platform (T-05-12 least-privilege).
  node_config {
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Cluster must be destroyable (free-tier deduction D-38-equivalent — no blocking destroy)
  deletion_protection = false

  resource_labels = local.common_tags
}

# --- Standalone node pool (D-41: explicit sizing, machine_type mapped from size) ---
# Zonal pool (location = var.zone) — a single node in one zone. This keeps the whole
# cluster in the free-tier zonal configuration (aligns with D-36) and avoids the
# regional-pool apply-time validation error (node_count must divide evenly across zones).
resource "google_container_node_pool" "this" {
  name     = "${var.project}-${var.environment}-pool"
  cluster  = google_container_cluster.this.id
  location = var.zone
  project  = var.gcp_project_id

  node_count = 1

  node_config {
    machine_type = local.machine_types[var.size]
    disk_size_gb = 20
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels       = local.common_tags
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
