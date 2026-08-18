# Storage Module — Canonical Interface

This directory documents the **canonical storage interface** that every cloud-specific
storage module (`oci/modules/storage`, `aws/modules/storage`, `gcp/modules/storage`)
must implement. It contains documentation only — no resources.

## Expected Variables

Every cloud storage module MUST accept these variables (or direct equivalents):

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project` | `string` | yes | Project name used for resource naming and tagging (validated: lowercase alphanumeric/hyphens, ≤ 31 chars) |
| `environment` | `string` | yes | Deployment environment (validated: `dev`, `staging`, `prod`) |
| `bucket_name` | `string` | yes | Name of the storage bucket (validated: lowercase alphanumeric/dots/hyphens, 3–63 chars) |
| `tags` | `map(string)` | no | Additional tags to merge with default tags (default: `{}`) |

## Expected Outputs

Every cloud storage module SHOULD expose these outputs (or direct equivalents):

| Output | Type | Description |
|--------|------|-------------|
| `bucket_name` | `string` | Name of the created storage bucket |
| `bucket_endpoint` | `string` | Provider endpoint URL for the bucket |

## Tagging

Modules apply the canonical tagging convention via a `locals` block:

```hcl
locals {
  common_tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "opentofu"
  })
}
```

Cloud-specific tag mapping: AWS `tags`, OCI `freeform_tags`, GCP `labels`.

## Naming Convention

Resource names follow `<project>-<env>-<cloud>-<resource>`. Use `this` as the
resource identifier when a single resource of a type exists in the module.
