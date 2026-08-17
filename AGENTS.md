<!-- GSD:project-start source:PROJECT.md -->
## Project

**Multi-Cloud Terraform Infrastructure**

A learning-focused but production-grade Terraform project managing infrastructure across OCI, AWS, and GCP. Built with reusable cloud-agnostic modules, parameterized configurations, and multi-environment support (dev/staging/prod). Designed to follow industrial IaC standards while keeping cloud costs minimal through free tier resources and ephemeral paid resources.

**Core Value:** Reusable, parameterized Terraform modules that work across cloud providers — the module abstraction layer is the primary learning outcome and the foundation everything else builds on.

### Constraints

- **Budget**: Free tier resources preferred; paid resources must be deletable/recreatable — minimize ongoing cloud costs
- **Tech Stack**: Terraform with OCI/AWS/GCP providers — no other IaC tools
- **Standards**: All modules must be reusable and parameterized — no hardcoded values, proper variable definitions with descriptions and validation
- **State**: Remote state backends per cloud provider — no local .tfstate files
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Engine
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **OpenTofu** | `>= 1.12.0` | IaC engine (HCL) | MPL 2.0 license, CNCF governance, built-in state encryption, `provider for_each`, `-exclude` flag. Terraform 1.15.x is BSL 1.1 — same HCL, same providers, but OpenTofu leads on features and has no license restrictions. For a greenfield learning project, OpenTofu is the lower-risk default (Scalr reports ~50% of IaC deployments now on OpenTofu). |
### Cloud Providers
| Provider | Source | Version Constraint | Latest (Aug 2026) | Confidence |
|----------|--------|-------------------|-------------------|------------|
| **hashicorp/aws** | `hashicorp/aws` | `~> 6.60` | 6.60.0 | HIGH — Most downloaded provider, 4.8B+ downloads. AWS provider releases weekly. |
| **hashicorp/google** | `hashicorp/google` | `~> 7.43` | 7.43.0 | HIGH — 2.3B downloads. Use `google` (GA features), not `google-beta` unless preview features needed. |
| **oracle/oci** | `oracle/oci` | `~> 8.26` | 8.26.0 | HIGH — 121M downloads. OCI backend requires Terraform/OpenTofu ≥ 1.12 for native state locking. |
### Remote State Backends
| Cloud | Backend Type | Locking | State Bucket Pattern | Free Tier Impact |
|-------|-------------|---------|---------------------|-----------------|
| **AWS** | `s3` | `use_lockfile = true` (S3 native, no DynamoDB) | `s3://tf-state-{env}-aws/` | S3 storage for state files: pennies/month. DynamoDB locking deprecated — use `use_lockfile`. |
| **GCP** | `gcs` | Native object locking | `gs://tf-state-{env}-gcp/` | GCS: 5 GB Always Free. State files are tiny. |
| **OCI** | `oci` | Native `If-None-Match` locking | `oci://tf-state-{env}-oci/` | Object Storage: 10 GB Always Free. Backend requires OpenTofu ≥ 1.12. |
# AWS — backend.tf
# GCP — backend.tf
# OCI — backend.tf
| Cloud | Recommended Auth | Why |
|-------|-----------------|-----|
| **AWS** | Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or AWS SSO | Standard for local dev; OIDC for CI/CD |
| **GCP** | Application Default Credentials (`gcloud auth application-default login`) | Standard for local dev; Workload Identity for CI/CD |
| **OCI** | OCI Config file (`~/.oci/config`) or Security Token | OCI backend supports `SecurityToken` auth for short-lived tokens |
### Dev Tooling
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| **tflint** | `v0.62.0` | Linter — catches invalid instance types, deprecated syntax, unused declarations | Always — run before plan/apply |
| **trivy** (replaces tfsec) | `latest` | Security scanner — misconfigurations, exposed secrets | Always — `trivy config .` |
| **terraform-docs** | `latest` | Auto-generate module READMEs with variable/output tables | When updating modules |
| **terraform fmt** | (built-in) | Canonical HCL formatting | Always — `tofu fmt -recursive` |
| **terraform validate** | (built-in) | Syntax/semantic validation | After `tofu init` |
### TFLint Plugin Configuration
# .tflint.hcl
## Free Tier Resource Defaults
### AWS Free Tier (12-month + Always Free)
| Resource | Free Tier Type | Always Free Type | Terraform Resource | Notes |
|----------|---------------|------------------|-------------------|-------|
| Compute | `t3.micro` (750 hrs/mo) | — | `aws_instance` | 12-month only. After expiry, ~$7.50/mo. |
| Database | `db.t3.micro` (750 hrs/mo, 20 GB) | — | `aws_db_instance` | Set `max_allocated_storage = 20` to prevent auto-scaling past free tier. |
| Object Storage | 5 GB (12-month) | S3 (5 GB, 12-month) | `aws_s3_bucket` | Use for state backend. |
| DynamoDB | 25 GB, 25 RCU/WCU | Always Free | `aws_dynamodb_table` | Not needed — use `use_lockfile` instead. |
| Lambda | 1M requests/mo | Always Free | `aws_lambda_function` | Good for learning serverless. |
| VPC | Free | Free | `aws_vpc` | **NO NAT Gateway** — that's ~$32/mo. Use public subnets for dev. |
| CloudWatch | 10 alarms | Always Free | `aws_cloudwatch_metric_alarm` | Set up billing alerts. |
### GCP Always Free (permanent)
| Resource | Free Tier Type | Terraform Resource | Notes |
|----------|---------------|-------------------|-------|
| Compute | `e2-micro` (1 instance) | `google_compute_instance` | **US regions only** (us-west1, us-central1, us-east1). Free in other regions = charges. |
| Object Storage | 5 GB | `google_storage_bucket` | Standard class, us- regions. |
| Cloud Functions | 2M invocations/mo | `google_cloudfunctions_function` | Always Free. |
| Cloud Run | 2M requests/mo | `google_cloud_run_service` | Always Free, any region. |
| BigQuery | 1 TB queries/mo | `google_bigquery_dataset` | Always Free. |
| VPC | Free | `google_compute_network` | Free. |
### OCI Always Free (permanent)
| Resource | Free Tier Type | Terraform Resource | Notes |
|----------|---------------|-------------------|-------|
| Compute (ARM) | 2 OCPU, 12 GB RAM (VM.Standard.A1.Flex) | `oci_core_instance` | Reduced from 4/24 in June 2026. Split as 1×2/12 or 2×1/6. |
| Compute (x86) | 2× VM.Standard.E2.1.Micro (1 GB each) | `oci_core_instance` | Separate from ARM quota. |
| Block Volume | 200 GB total | `oci_core_volume` | Boot volumes count against this. |
| Object Storage | 10 GB | `oci_objectstorage_bucket` | Free. |
| Autonomous DB | 1 OCPU, 20 GB | `oci_database_autonomous_database` | Always Free. |
| Load Balancer | 1 flex LB | `oci_load_balancer_load_balancer` | Always Free. |
| VCN | Free | `oci_core_vcn` | Free. |
## Installation
### OpenTofu
# Linux (official installer)
# Or via package manager
# Debian/Ubuntu
# macOS
# Verify
### Cloud CLIs
# AWS CLI v2
# Google Cloud CLI
# OCI CLI
### Dev Tools
# tflint
# trivy
# terraform-docs
# Or: brew install terraform-docs
### Pre-commit Hooks (optional but recommended)
# .pre-commit-config.yaml
## Alternatives Considered
| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| IaC Engine | OpenTofu 1.12 | Terraform 1.15 | BSL license, lacks state encryption and provider for_each in open CLI |
| IaC Engine | OpenTofu 1.12 | Pulumi 3.x | Project requires Terraform/HCL, not general-purpose languages |
| State Backend | Per-cloud native (s3/gcs/oci) | HCP Terraform | Free tier is 500 resources — insufficient for learning project with 3 clouds. Self-managed backends are free. |
| Security Scanner | trivy | tfsec | tfsec is EOL (checks folded into trivy in 2023) |
| Multi-env Tool | Terraform directories | Terragrunt | Overkill for 9 configurations. Terragrunt adds HCL abstraction layer without proportional benefit. |
| State Locking (AWS) | S3 native `use_lockfile` | DynamoDB table | DynamoDB locking is deprecated and will be removed. Native S3 locking is simpler and free. |
| OCI Backend | Native `oci` backend | S3-compatible backend | S3-compatible lacks state locking. OCI backend (requires TF/OT ≥ 1.12) provides native locking. |
## Version Summary (copy-paste ready)
# versions.tf
## Sources
| Source | Confidence | Date |
|--------|-----------|------|
| [OpenTofu vs Terraform 2026 (Markaicode)](https://markaicode.com/benchmarks/terraform-benchmark/) | HIGH — multiple independent sources agree | May 2026 |
| [OpenTofu vs Terraform 2026 (Scalr)](https://scalr.com/learning-center/opentofu-vs-terraform) | HIGH — vendor comparison with citations | May 2026 |
| [Terraform vs OpenTofu (SquareOps)](https://squareops.com/blog/opentofu-vs-terraform-2026/) | HIGH — CNCF context verified | Jun 2026 |
| [Terraform Multi-Cloud Patterns (CloudToolStack)](https://cloudtoolstack.com/learn/multi-cloud-terraform-patterns-guide) | MEDIUM — patterns guide | Mar 2026 |
| [Terraform Is Multi-Provider (OneUptime)](https://oneuptime.com/blog/post/2026-08-04-terraform-multi-provider-stable-module-interface/) | HIGH — practical architecture advice | Aug 2026 |
| [OCI Backend (HashiCorp Docs)](https://developer.hashicorp.com/terraform/language/backend/oci) | HIGH — official documentation | Nov 2025 |
| [S3 Backend (HashiCorp Docs)](https://developer.hashicorp.com/terraform/language/backend/s3) | HIGH — official documentation | Current |
| [GCS Backend (HashiCorp Docs)](https://developer.hashicorp.com/terraform/language/backend/gcs) | HIGH — official documentation | Current |
| [AWS Free Tier](https://aws.amazon.com/free/) | HIGH — official | Current |
| [GCP Free Tier](https://docs.cloud.google.com/free/docs/free-cloud-features) | HIGH — official | Current |
| [OCI Free Tier](https://www.oracle.com/cloud/free/) | HIGH — official | Current |
| [OCI Free Tier ARM reduction (InfoQ)](https://www.infoq.com/news/2026/07/oracle-cloud-free-tier-limits/) | HIGH — verified with official docs | Jul 2026 |
| [26 Most Useful Terraform Tools (Spacelift)](https://spacelift.io/blog/terraform-tools) | MEDIUM — tool recommendations | Jun 2026 |
| [TFLint GitHub](https://github.com/terraform-linters/tflint) | HIGH — official repo | Apr 2026 |
| [Trivy replaces tfsec (Spacelift)](https://spacelift.io/blog/terraform-tools) | HIGH — multiple confirmations | Jun 2026 |
| [cani.tf feature comparison](https://cani.tf/) | HIGH — live comparison tool | May 2026 |
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
