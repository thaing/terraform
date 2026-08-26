# Multi-Cloud Terraform Infrastructure

A learning-focused but production-grade Terraform/OpenTofu project managing infrastructure across Oracle Cloud Infrastructure (OCI), Amazon Web Services (AWS), and Google Cloud Platform (GCP).

Built with reusable cloud-specific modules, parameterized configurations, and multi-environment support (dev/staging/prod). Designed to follow industrial IaC standards while keeping cloud costs minimal through free tier resources.

## Prerequisites

- **OpenTofu** >= 1.12.0 (https://opentofu.org)
- Cloud CLIs configured per environment (AWS, GCP, OCI) — required for remote state backends

## Directory Structure

This project uses a **hybrid layout** — top-level by cloud, resource types within each:

```
terraform/
├── .gitignore
├── .tflint.hcl
├── README.md
│
├── modules/                          # Shared interface documentation
│   ├── compute/                      # Canonical compute interface docs
│   ├── networking/                   # Canonical networking interface docs
│   └── storage/                      # Canonical storage interface docs
│
├── oci/
│   ├── modules/                      # OCI-specific module implementations
│   │   ├── compute/
│   │   ├── networking/
│   │   └── storage/
│   └── environments/                 # OCI root modules per environment
│       ├── dev/
│       ├── staging/
│       └── prod/
│
├── aws/
│   ├── modules/                      # AWS-specific module implementations
│   │   ├── compute/
│   │   ├── networking/
│   │   └── storage/
│   └── environments/                 # AWS root modules per environment
│       ├── dev/
│       ├── staging/
│       └── prod/
│
└── gcp/
    ├── modules/                      # GCP-specific module implementations
    │   ├── compute/
    │   ├── networking/
    │   └── storage/
    └── environments/                 # GCP root modules per environment
        ├── dev/
        ├── staging/
        └── prod/
```

## Key Design Decisions

- **OpenTofu** >= 1.12.0 as the IaC engine (MPL 2.0, CNCF governance)
- **Cloud-specific modules** with consistent variable/output interfaces (not abstraction wrappers)
- **Directory-based environment separation** (no workspaces)
- **Per-cloud state bucket** with per-environment key prefixes (`dev/`, `staging/`, `prod/`)
- **Free tier first** — paid resources must be deletable/recreatable

## Provider Versions

| Cloud | Provider | Constraint |
|-------|----------|------------|
| OCI | `oracle/oci` | `~> 8.26` |
| AWS | `hashicorp/aws` | `~> 6.60` |
| GCP | `hashicorp/google` | `~> 7.43` |

## Usage

```bash
# Initialize a specific environment
cd oci/environments/dev
tofu init
tofu plan

# Format all files
tofu fmt -recursive
```
