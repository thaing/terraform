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

  # Shape configs: A1.Flex is flexible (OCPU/memory configurable); E2.1 is fixed (1 OCPU/1 GB).
  # small/medium/large tiers map to A1.Flex sizes within the Always Free 2 OCPU / 12 GB cap.
  # For E2.1, size is ignored (fixed shape); for other shapes, small=1/6, medium=1/6, large=2/12.
  shape_config = {
    "VM.Standard.A1.Flex" = {
      small  = { ocpus = 1, memory_in_gbs = 6 }
      medium = { ocpus = 1, memory_in_gbs = 6 }
      large  = { ocpus = 2, memory_in_gbs = 12 }
    }
    "VM.Standard.E2.1" = {
      small  = { ocpus = 1, memory_in_gbs = 1 }
      medium = { ocpus = 1, memory_in_gbs = 1 }
      large  = { ocpus = 1, memory_in_gbs = 1 }
    }
    "VM.Standard.E2.2" = {
      small  = { ocpus = 1, memory_in_gbs = 15 }
      medium = { ocpus = 1, memory_in_gbs = 15 }
      large  = { ocpus = 2, memory_in_gbs = 30 }
    }
    "VM.Standard.E2.4" = {
      small  = { ocpus = 2, memory_in_gbs = 30 }
      medium = { ocpus = 2, memory_in_gbs = 30 }
      large  = { ocpus = 4, memory_in_gbs = 60 }
    }
    "VM.Standard.E2.8" = {
      small  = { ocpus = 4, memory_in_gbs = 60 }
      medium = { ocpus = 4, memory_in_gbs = 60 }
      large  = { ocpus = 8, memory_in_gbs = 120 }
    }
    "VM.Standard.E3.Flex" = {
      small  = { ocpus = 1, memory_in_gbs = 6 }
      medium = { ocpus = 1, memory_in_gbs = 6 }
      large  = { ocpus = 2, memory_in_gbs = 12 }
    }
    "VM.Standard.E4.Flex" = {
      small  = { ocpus = 1, memory_in_gbs = 6 }
      medium = { ocpus = 1, memory_in_gbs = 6 }
      large  = { ocpus = 2, memory_in_gbs = 12 }
    }
    "VM.Standard.E5.Flex" = {
      small  = { ocpus = 1, memory_in_gbs = 6 }
      medium = { ocpus = 1, memory_in_gbs = 6 }
      large  = { ocpus = 2, memory_in_gbs = 12 }
    }
    "VM.Standard.E6.Flex" = {
      small  = { ocpus = 1, memory_in_gbs = 6 }
      medium = { ocpus = 1, memory_in_gbs = 6 }
      large  = { ocpus = 2, memory_in_gbs = 12 }
    }
  }

  # Effective shape config for the selected node_shape, falling back to A1.Flex defaults.
  effective_shape_config = lookup(local.shape_config, var.node_shape, local.shape_config["VM.Standard.A1.Flex"])

  # Shapes that support node_shape_config (Flex shapes). Fixed shapes like E2.1 don't.
  is_flex_shape = contains(["VM.Standard.A1.Flex", "VM.Standard.E3.Flex", "VM.Standard.E4.Flex", "VM.Standard.E5.Flex", "VM.Standard.E6.Flex", "VM.Standard.E2.2", "VM.Standard.E2.4", "VM.Standard.E2.8"], var.node_shape)

  # Pin the OKE Kubernetes version when var.k8s_version is set; otherwise use the newest
  # version OKE reports for the region (kubernetes_versions is returned newest-first by the API).
  kubernetes_version = var.k8s_version != "" ? var.k8s_version : data.oci_containerengine_cluster_option.oke.kubernetes_versions[0]

  # Extract major.minor from cluster version (e.g., "1.33" from "v1.33.0") to match
  # node images by their OKE version prefix in source_name.
  cluster_major_minor = replace(local.kubernetes_version, "/^v?(\\d+\\.\\d+).*$/", "$1")

  # Determine if we need ARM (aarch64) or x86_64 image based on node_shape.
  is_arm_shape = var.node_shape == "VM.Standard.A1.Flex"

  # Filter sources to images matching the cluster's major.minor OKE version AND architecture.
  # source_name format: "Oracle-Linux-9.8-aarch64-2026.08.14-0-OKE-1.33.10-1699" (ARM)
  #                   "Oracle-Linux-9.8-2026.08.14-0-OKE-1.33.10-1699" (x86_64)
  # Exclude GPU images for both architectures.
  matching_sources = [for s in data.oci_containerengine_node_pool_option.oke.sources : s
    if strcontains(s.source_name, "OKE-${local.cluster_major_minor}")
    && !strcontains(s.source_name, "GPU")
    && (local.is_arm_shape ? strcontains(s.source_name, "aarch64") : !strcontains(s.source_name, "aarch64"))]

  # Debug: use a specific known-good image for x86 shapes if matching fails
  x86_candidates = [for s in data.oci_containerengine_node_pool_option.oke.sources : s
    if strcontains(s.source_name, "OKE-${local.cluster_major_minor}")
    && !strcontains(s.source_name, "aarch64")
    && strcontains(s.source_name, "Oracle-Linux-9.8-")
    && !strcontains(s.source_name, "GPU")]
  fallback_x86_image = length(local.x86_candidates) > 0 ? local.x86_candidates[0].image_id : data.oci_containerengine_node_pool_option.oke.sources[0].image_id

  # Use the first matching image; extract its exact OKE version for the node pool kubernetes_version.
  node_image_id      = length(local.matching_sources) > 0 ? local.matching_sources[0].image_id : (local.is_arm_shape ? data.oci_containerengine_node_pool_option.oke.sources[0].image_id : local.fallback_x86_image)
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
  node_shape         = var.node_shape

  dynamic "node_shape_config" {
    for_each = local.is_flex_shape ? [1] : []
    content {
      ocpus         = local.effective_shape_config[var.size].ocpus
      memory_in_gbs = local.effective_shape_config[var.size].memory_in_gbs
    }
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