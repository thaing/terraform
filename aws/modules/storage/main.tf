locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

resource "aws_s3_bucket" "storage" {
  bucket = var.bucket_name
  tags   = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# D-29: Versioning enabled via separate resource (inline block deprecated in provider v6.x)
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}
