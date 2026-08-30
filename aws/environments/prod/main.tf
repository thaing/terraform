provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

module "networking" {
  source              = "../../modules/networking"
  project             = var.project
  environment         = var.environment
  cidr_block          = var.cidr_block
  ssh_source_cidr     = var.ssh_source_cidr
  availability_zone   = var.availability_zone
  availability_zone_b = var.availability_zone_b
  tags                = local.common_tags
}

module "compute" {
  source             = "../../modules/compute"
  project            = var.project
  environment        = var.environment
  tags               = local.common_tags
  size               = var.size
  subnet_id          = module.networking.public_subnet_id
  security_group_id  = module.networking.security_group_id
  public_key_openssh = var.public_key_openssh
  region             = var.region
  image_id           = var.image_id
}

module "storage" {
  source      = "../../modules/storage"
  project     = var.project
  environment = var.environment
  tags        = local.common_tags
  bucket_name = var.storage_bucket_name
}

module "budget" {
  source            = "../../modules/budget"
  project           = var.project
  environment       = var.environment
  tags              = local.common_tags
  cost_alert_amount = var.cost_alert_amount
  alert_email       = var.alert_email
}

module "kubernetes" {
  source             = "../../modules/kubernetes"
  project            = var.project
  environment        = var.environment
  tags               = local.common_tags
  size               = var.size_k8s
  vpc_id             = module.networking.network_id
  subnet_ids         = module.networking.public_subnet_ids
  public_key_openssh = var.public_key_openssh
  region             = var.region
  k8s_version        = var.k8s_version
}

data "aws_eks_cluster_auth" "this" {
  name = module.kubernetes.cluster_id
}

provider "kubernetes" {
  host                   = module.kubernetes.cluster_endpoint
  cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = module.kubernetes.cluster_endpoint
    cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# D-43/D-53: Cilium CNI in chaining/ENI mode alongside VPC CNI (kubeProxyReplacement=false) —
# lowest-risk option for this learning project; strict kube-proxy replacement deferred
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

# D-45: nginx hello-world workload proving deployments work
resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "25.1.5"
  namespace  = "default"
}
