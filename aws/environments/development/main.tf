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

# ssh security group
module "ssh_sg" {
  source = "../../modules/sg"
  
  ingress_rules = {
    ssh_within_vpc = {
      description = "SSH from internal network"
      from_port   = 22
      to_port     = 22
      ip_protocol    = "tcp"
      cidr_ipv4 = var.cidr_block
    }
    ssh_from_home = {
      description = "SSH from home"
      from_port   = 22
      to_port     = 22
      ip_protocol    = "tcp"
      cidr_ipv4 = var.ssh_source_cidr
    }
  }

  project = var.project
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  name = "ssh-${var.environment}"
  description = "Allow SSH ingress"
}
