provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-s3-bucket"
  })
}

# Create S3 state bucket
module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.1"

  bucket = "${var.project}-tf-state"
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
