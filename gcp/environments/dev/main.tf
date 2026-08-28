provider "google" {
  project = var.gcp_project_id
  region  = var.region
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
