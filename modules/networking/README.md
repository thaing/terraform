# Networking Module — Canonical Interface

This directory documents the **canonical networking interface** that every
cloud-specific networking module (`oci/modules/networking`, `aws/modules/networking`,
`gcp/modules/networking`) must implement. It contains documentation only — no resources.

## Canonical Interface

Every cloud networking module MUST accept these variables (or direct equivalents):

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project` | `string` | yes | Project name used for resource naming and tagging (validated: lowercase alphanumeric/hyphens, ≤ 31 chars) |
| `environment` | `string` | yes | Deployment environment (validated: `dev`, `staging`, `prod`) |
| `cidr_block` | `string` | yes | CIDR block for the VPC/VCN/network (validated: valid IPv4 CIDR) |
| `tags` | `map(string)` | no | Additional tags to merge with default tags (default: `{}`) |

## Expected Outputs

Every cloud networking module SHOULD expose these outputs (or direct equivalents):

| Output | Type | Description |
|--------|------|-------------|
| `vcn_id` / `vpc_id` / `network_id` | `string` | Provider-specific network identifier |
| `subnet_id` | `string` | Identifier of the primary subnet created |

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
