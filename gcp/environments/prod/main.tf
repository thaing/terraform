provider "google" {
  project               = var.gcp_project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.gcp_project_id
}

locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

module "networking" {
  source          = "../../modules/networking"
  project         = var.project
  environment     = var.environment
  cidr_block      = var.cidr_block
  ssh_source_cidr = var.ssh_source_cidr
  region          = var.region
  tags            = local.common_tags
}

module "compute" {
  source             = "../../modules/compute"
  project            = var.project
  environment        = var.environment
  tags               = local.common_tags
  size               = var.size
  subnet_id          = module.networking.public_subnet_id
  public_key_openssh = var.public_key_openssh
  region             = var.region
  image              = var.image
  public_ip          = var.public_ip
}

module "storage" {
  source      = "../../modules/storage"
  project     = var.project
  environment = var.environment
  tags        = local.common_tags
  bucket_name = var.storage_bucket_name
  region      = var.region
}

module "budget" {
  source             = "../../modules/budget"
  project            = var.project
  environment        = var.environment
  billing_account_id = var.billing_account_id
  cost_alert_amount  = var.cost_alert_amount
  alert_email        = var.alert_email
}

module "kubernetes" {
  source                       = "../../modules/kubernetes"
  project                      = var.project
  environment                  = var.environment
  tags                         = local.common_tags
  size                         = var.size_k8s
  network                      = module.networking.network_id
  subnetwork                   = module.networking.public_subnet_id
  secondary_pod_range_name     = module.networking.secondary_pod_range_name
  secondary_service_range_name = module.networking.secondary_service_range_name
  gcp_project_id               = var.gcp_project_id
  region                       = var.region
  zone                         = var.zone
  public_key_openssh           = var.public_key_openssh
}

# GKE auth token drives the helm/kubernetes providers + kubeconfig (T-05-11: sensitive)
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = module.kubernetes.cluster_endpoint
  cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes = {
    host                   = module.kubernetes.cluster_endpoint
    cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}

# D-49: node-observability metrics chart (3.14.0 = app v0.9.0) for HPA + basic observability.
# GKE uses Dataplane V2 (Cilium built-in) — NO separate Cilium install (D-53/B2).
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.14.0"
  namespace  = "kube-system"
}

# D-45: nginx hello-world workload proving deployments work
resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "25.1.5"
  namespace  = "default"
}
