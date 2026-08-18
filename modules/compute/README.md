# Compute Module — Canonical Interface

This directory documents the **canonical compute interface** that every cloud-specific
compute module (`oci/modules/compute`, `aws/modules/compute`, `gcp/modules/compute`)
must implement. It contains documentation only — no resources.

## Expected Variables

Every cloud compute module MUST accept these variables (or direct equivalents):

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project` | `string` | yes | Project name used for resource naming and tagging (validated: lowercase alphanumeric/hyphens, ≤ 31 chars) |
| `environment` | `string` | yes | Deployment environment (validated: `dev`, `staging`, `prod`) |
| `size` | `string` | yes | Instance size tier (validated: `small`, `medium`, `large`) |
| `subnet_id` | `string` | yes | Subnet/network where the instance is placed |
| `tags` | `map(string)` | no | Additional tags to merge with default tags (default: `{}`) |

## Expected Outputs

Every cloud compute module SHOULD expose these outputs (or direct equivalents):

| Output | Type | Description |
|--------|------|-------------|
| `instance_id` | `string` | Provider-assigned instance identifier |
| `private_ip` | `string` | Private IP address of the instance |

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
