locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  public_subnet_cidr  = cidrsubnet(var.cidr_block, 8, 0)
  private_subnet_cidr = cidrsubnet(var.cidr_block, 8, 1)
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  cidr_block     = var.cidr_block
  display_name   = "${var.project}-${var.environment}-vcn"
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project}-${var.environment}-igw"
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project}-${var.environment}-sl"

  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.ssh_source_cidr

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"

    icmp_options {
      type = 8
      code = 0
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.main.id
  cidr_block          = local.public_subnet_cidr
  availability_domain = var.availability_domain
  route_table_id      = oci_core_route_table.public.id
  security_list_ids   = [oci_core_security_list.public.id]
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = local.private_subnet_cidr
  availability_domain        = var.availability_domain
  prohibit_public_ip_on_vnic = true
}
