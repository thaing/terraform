provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

# Create S3 state bucket
module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  bucket = "x-${var.project}-tf-state"
  tags   = local.common_tags

  versioning = {
    enabled = true
  }

}

# Configure to expire noncurrent objects after 365 days old
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = module.state_bucket.s3_bucket_id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = module.state_bucket.s3_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create budget alerts here
module "budget" {
  source            = "../modules/budget"
  project           = var.project
  tags              = local.common_tags
  budget_name       = "${var.project}-total-cost"
  cost_alert_amount = var.cost_alert_amount
  alert_email       = var.alert_email
}

module "ec2_budget" {
  source            = "../modules/budget"
  project           = var.project
  tags              = local.common_tags
  budget_name       = "${var.project}-ec2-cost"
  cost_alert_amount = var.cost_alert_amount
  alert_email       = var.alert_email

  # Example to filter a service
  cost_filter = {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }
  # Change it to true or comment out to create this budget alerts
  create_budget = false
}