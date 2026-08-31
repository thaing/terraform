# Hand-authored module (deliberate) — providers come from the registry, this module layer is
# hand-written per the project's core learning outcome (see research/ARCHITECTURE.md
# "Pattern: Hand-Authored Modules over Registry Modules").
# Production registry alternative: oracle-terraform-modules/terraform-oci-oke
#   (https://registry.terraform.io/modules/oracle-terraform-modules/terraform-oci-oke)
#   — full OKE landing zone wrapper; prefer it for a production, non-learning project.
locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # D-41/D-42: size tier -> OKE node shape config. small/medium stay at 1 OCPU/6 GB so a single
  # A1 node pool remains within the OCI Always Free ARM cap of 2 OCPU / 12 GB total (RESEARCH §3,
  # post-June-2026 reduction) even alongside other A1 compute. Only large uses the full cap.
  shape_config = {
    small  = { ocpus = 1, memory_in_gbs = 6 }
    medium = { ocpus = 1, memory_in_gbs = 6 }
    large  = { ocpus = 2, memory_in_gbs = 12 }
  }

  # Pin the OKE Kubernetes version when var.k8s_version is set; otherwise use the newest
  # version OKE reports for the region (kubernetes_versions is returned newest-first by the API).
  kubernetes_version = var.k8s_version != "" ? var.k8s_version : data.oci_containerengine_cluster_option.oke.kubernetes_versions[0]

  # Extract major.minor from cluster version (e.g., "1.33" from "v1.33.0") to match
  # node images by their OKE version prefix in source_name.
  cluster_major_minor = replace(local.kubernetes_version, "/^v?(\\d+\\.\\d+).*$/", "$1")

  # Filter sources to images whose source_name contains the cluster's major.minor OKE version.
  # source_name format: "Oracle-Linux-9.8-aarch64-2026.08.14-0-OKE-1.33.10-1699"
  matching_sources = [for s in data.oci_containerengine_node_pool_option.oke.sources : s if strcontains(s.source_name, "OKE-${local.cluster_major_minor}")]

  # Use the first matching image; extract its exact OKE version for the node pool kubernetes_version.
  node_image_id      = length(local.matching_sources) > 0 ? local.matching_sources[0].image_id : data.oci_containerengine_node_pool_option.oke.sources[0].image_id
  node_pool_version  = length(local.matching_sources) > 0 ? "v${regex("OKE-([\\d.]+)-", local.matching_sources[0].source_name)[0]}" : local.kubernetes_version
}

data "oci_containerengine_cluster_option" "oke" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "oke" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

# --- OKE cluster (D-34/D-37/D-48: Enhanced type, free control plane, native OCI workload identity) ---
# NOTE: this is the correct OCI provider container-engine resource per RESEARCH Key Finding §1
# (the container-edition misspelling from older CONTEXT docs does not exist in the provider —
# acceptance greps enforce zero occurrences of that misspelling here).
resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  name               = "${var.project}-${var.environment}-oke"
  vcn_id             = var.vcn_id
  kubernetes_version = local.node_pool_version
  type               = "ENHANCED_CLUSTER"

  # Public endpoint so kubectl/helm can reach the API from the internet (T-05-23:
  # exposure limited by the Phase 3 public-subnet security list in the VCN)
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = var.subnet_ids[0]
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
    }
  }

  freeform_tags = local.common_tags
}

# --- OKE node pool (D-42: Always-Free ARM shape within the 2/12 cap) ---
resource "oci_containerengine_node_pool" "this" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_id
  name               = "${var.project}-${var.environment}-pool"
  kubernetes_version = local.node_pool_version
  node_shape         = "VM.Standard.A1.Flex"

  node_shape_config {
    ocpus         = local.shape_config[var.size].ocpus
    memory_in_gbs = local.shape_config[var.size].memory_in_gbs
  }

  # Modern placement form (node_config_details replaces the deprecated subnet_ids list);
  # single node on the REGIONAL private subnet (subnet_ids[1]). The public subnet (subnet_ids[0])
  # is used only for the cluster endpoint — OCI marks it as a "service subnet" which node pools
  # cannot use. The private subnet has a NAT gateway for outbound image pulls.
  node_config_details {
    size = 1
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = var.subnet_ids[1]
    }
  }

  # OKE node image resolved from the provider's node pool options (default OKE image for
  # the region — no hardcoded OCID, per the no-hardcoded-values standard)
  node_source_details {
    source_type = "IMAGE"
    image_id    = local.node_image_id
  }

  ssh_public_key = var.public_key_openssh
  freeform_tags  = local.common_tags
}

# --- Kubeconfig (token_version 2.0.0 for static token auth; 3.0.0 uses exec/OCI-CLI which
# the helm/kubernetes Terraform providers cannot invoke) ---
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id    = oci_containerengine_cluster.this.id
  token_version = "2.0.0"
}