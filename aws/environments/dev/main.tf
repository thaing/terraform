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
  source            = "../../modules/networking"
  project           = var.project
  environment       = var.environment
  cidr_block        = var.cidr_block
  ssh_source_cidr   = var.ssh_source_cidr
  availability_zone = var.availability_zone
  tags              = local.common_tags
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
