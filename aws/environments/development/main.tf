provider "aws" {
  region = var.region
}

# Create dev vpc
module "vpc" {
  source      = "../../modules/vpc"
  
  project     = var.project
  environment = var.environment
  cidr_block  = var.cidr_block
  tags        = var.tags
}
