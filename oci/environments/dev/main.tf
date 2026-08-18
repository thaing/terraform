locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}

# Module calls will be wired when module resources are implemented (Phase 3+)
