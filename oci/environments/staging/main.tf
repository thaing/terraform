provider "oci" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })

  # OKE kubeconfig carries the CA + token the helm/kubernetes providers need
  oke_auth = yamldecode(module.kubernetes.kubeconfig)
}

module "networking" {
  source              = "../../modules/networking"
  project             = var.project
  environment         = var.environment
  cidr_block          = var.cidr_block
  ssh_source_cidr     = var.ssh_source_cidr
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  tags                = local.common_tags
}

module "compute" {
  source                = "../../modules/compute"
  project               = var.project
  environment           = var.environment
  tags                  = local.common_tags
  size                  = var.size
  subnet_id             = module.networking.public_subnet_id
  public_key_openssh    = var.public_key_openssh
  availability_domain   = var.availability_domain
  compartment_id        = var.compartment_id
  image_id              = var.image_id
  shape                 = var.shape
  second_volume_size_gb = 50
}

module "storage" {
  source         = "../../modules/storage"
  project        = var.project
  environment    = var.environment
  tags           = local.common_tags
  bucket_name    = var.storage_bucket_name
  compartment_id = var.compartment_id
}

module "budget" {
  source            = "../../modules/budget"
  project           = var.project
  environment       = var.environment
  compartment_id    = var.compartment_id
  tenancy_id        = var.tenancy_id
  cost_alert_amount = var.cost_alert_amount
  alert_email       = var.alert_email
}

# --- Kubernetes (OKE, D-34) ---
module "kubernetes" {
  source              = "../../modules/kubernetes"
  project             = var.project
  environment         = var.environment
  tags                = local.common_tags
  size                = var.size_k8s
  vcn_id              = module.networking.network_id
  subnet_ids          = [module.networking.public_subnet_id]
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  public_key_openssh  = var.public_key_openssh
}

provider "kubernetes" {
  host                   = module.kubernetes.cluster_endpoint
  cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
  token                  = local.oke_auth.users[0].user.token
}

provider "helm" {
  kubernetes = {
    host                   = module.kubernetes.cluster_endpoint
    cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
    token                  = local.oke_auth.users[0].user.token
  }
}

# D-43/W3: Cilium CNI in chaining mode alongside the OKE default CNI (kubeProxyReplacement=false) —
# committed default per D-43; full kube-proxy/Flannel replacement on OKE deferred (no OKE-specific
# Cilium install path exists upstream — verified against docs.cilium.io stable)
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.20.1"
  namespace  = "kube-system"

  set = [{
    name  = "kubeProxyReplacement"
    value = "false"
  }]
}

# D-49: metrics-server app v0.9.0 (helm chart 3.14.0) for HPA + basic observability
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"
}

# D-45: nginx hello-world workload proving deployments work on OKE
resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "25.1.5"
  namespace  = "default"
}
