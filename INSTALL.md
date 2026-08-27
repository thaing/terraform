# Install — Multi-Cloud Terraform Infrastructure

> Step-by-step guide to deploy servers, storage, and networking on AWS, GCP, and OCI.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Backend Architecture](#2-backend-architecture)
3. [Credential Setup](#3-credential-setup)
4. [AWS Deployment](#4-aws-deployment)
5. [GCP Deployment](#5-gcp-deployment)
6. [OCI Deployment](#6-oci-deployment)
7. [Phase 3 — Networking & IAM Apply](#7-phase-3--networking--iam-apply)
8. [Verify Deployment](#8-verify-deployment)
9. [Cleanup / Destroy](#9-cleanup--destroy)
10. [Troubleshooting](#10-troubleshooting)
11. [Known Gaps & Notes](#11-known-gaps--notes)
12. [Kubernetes (Coming Soon)](#12-kubernetes-coming-soon)

---

## 1. Prerequisites

### Install OpenTofu

```bash
# Linux (Debian/Ubuntu)
curl -fsSL https://get.opentofu.org/install | sh

# macOS
brew install opentofu

# Verify
tofu version
# Should show: OpenTofu v1.12.x
```

### Install Cloud CLIs

Install only the clouds you plan to use:

```bash
# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Google Cloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
or
brew install oci-cli
```

### Optional Dev Tools

These tools are **optional** — you can deploy without them. They help keep configuration clean and secure as the project grows.

Verify each is installed with `--version` (e.g. `tflint --version`); if the command isn't found, run the install line for it.

#### tflint — Terraform linter

Catches invalid instance types, deprecated syntax, and unused declarations before you plan/apply. Uses the project's `.tflint.hcl`, which enables the terraform, aws, and google plugin rulesets.

```bash
# Install (macOS — Homebrew core dropped the formula; use the official tap)
brew install terraform-linters/tap/tflint

# First-time only: download the plugin rulesets declared in .tflint.hcl
tflint --init

# Run from a cloud root (e.g. aws/environments/dev) to lint that configuration
tflint
```

> **Note:** TFLint has no OCI ruleset, so linting covers AWS/GCP only — OCI relies on `tofu validate` alone.

#### trivy — security / misconfiguration scanner

Scans IaC and files for misconfigurations, exposed secrets, and unsafe defaults.

```bash
# Install (macOS)
brew install trivy

# Scan the whole project from the repo root
trivy config .
```

#### terraform-docs — module README generation

Auto-generates the variable/output tables used in module READMEs, so docs stay in sync with the code.

```bash
# Install (macOS)
brew install terraform-docs

# Regenerate a module README (run from the repo root)
terraform-docs markdown table --output-file README.md aws/modules/compute
```

### Project Structure

```
terraform/
├── aws/
│   ├── bootstrap/          # Creates the shared state bucket
│   ├── identity/           # IAM role + policy
│   ├── modules/
│   │   ├── compute/        # EC2 instances
│   │   ├── networking/     # VPC, subnets, SG
│   │   └── storage/        # S3 buckets
│   └── environments/
│       ├── dev/            # Dev environment root
│       ├── staging/        # Staging environment root
│       └── prod/           # Production environment root
├── gcp/                    # Same structure for GCP
├── oci/                    # Same structure for OCI
```

### Deploy Order

Each cloud follows the same 3-step order:

```
Step 1: bootstrap   → creates state bucket (remote state lives here)
Step 2: identity    → creates IAM identity (compute/storage scoped to this)
Step 3: environments/{dev,staging,prod} → deploys actual infrastructure
```

---

## 2. Backend Architecture

Each environment root module uses a **partial backend configuration** — the `backend.tf` file declares only the backend type (`backend "s3"`, `backend "gcs"`, etc.), while the actual values (bucket name, key/prefix, region, flags) live in a committed `backend.tfbackend` file:

```bash
tofu init -backend-config=backend.tfbackend
```

### Single bucket per cloud

The topology is **3 state buckets — one per cloud**, shared across environments via key/prefix directories:

| Cloud | Bucket | State isolation |
|-------|--------|----------------|
| AWS | `multicloud-tf-aws-state` | S3 key: `{env}/terraform.tfstate` |
| GCP | `multicloud-tf-gcp-state-<project-id>` | GCS prefix: `{env}/terraform` |
| OCI | `multicloud-tf-oci-state` | S3 key: `{env}/terraform.tfstate` (S3-compat endpoint) |

Identity stacks store state at `dev/identity/terraform.tfstate` inside the same bucket.

### Backend types and locking

| Cloud | Backend | Locking |
|-------|---------|---------|
| AWS | `s3` (native) | `use_lockfile = true` (S3 conditional writes) |
| GCP | `gcs` (native) | Native object locking |
| OCI | `s3` (S3-compat endpoint) | **None** (see [Known Gaps](#11-known-gaps--notes)) |

### Why `.tfbackend` files?

User-specific values (OCI tenancy namespace, GCP project ID) must not be committed to git. The `.tfbackend` files hold these identifiers per environment and are gitignored where needed — keeping the committed `backend.tf` clean and clone-safe.

---

## 3. Credential Setup

### AWS

```bash
aws configure
# sets AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / default region
```

Or export environment variables directly:

```bash
export AWS_ACCESS_KEY_ID="<access-key>"
export AWS_SECRET_ACCESS_KEY="<secret-key>"
export AWS_DEFAULT_REGION="us-east-1"
```

Or use SSO:

```bash
aws sso login
```

### GCP

```bash
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
gcloud config get-value project   # capture this value — used as the bucket-name suffix
```

### OCI

```bash
oci setup config                  # creates ~/.oci/config
oci os ns get                     # capture your Object Storage namespace
```

Then create an **OCI Customer Secret Key** (Console → Identity → Users → your user → Customer Secret Keys) and store it in an AWS shared-credentials profile named `oci-state` — the S3-compatibility state backend authenticates through it via `profile = "oci-state"` in each OCI `.tfbackend` file:

```ini
# ~/.aws/credentials   (chmod 600)
[oci-state]
aws_access_key_id = <customer-secret-access-key>
aws_secret_access_key = <customer-secret-secret-key>
```

> **Why a named profile instead of exporting `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`:** those same variables drive the real AWS provider in the `aws/` stacks. An OCI secret key exported as default AWS credentials makes every `aws/` plan fail with confusing signature errors — a dedicated profile keeps the two clouds isolated.

---

## 4. AWS Deployment

### Step 1: Create State Bucket (bootstrap)

```bash
cd aws/bootstrap

# Create terraform.tfvars (gitignored)
cat > terraform.tfvars << 'EOF'
project = "multicloud-tf"
region  = "us-east-1"
EOF

# Initialize and apply
tofu init
tofu plan      # Review what will be created
tofu apply     # Creates the state bucket
```

**Expected output:** `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

### Step 2: Create IAM Identity

```bash
cd aws/identity

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $ACCOUNT_ID"

# Create terraform.tfvars
cat > terraform.tfvars << EOF
project         = "multicloud-tf"
region          = "us-east-1"
trust_principal = "arn:aws:iam::${ACCOUNT_ID}:user/<your-iam-user-name>"
EOF
# Replace <your-iam-user-name> with your actual IAM username

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

**Outputs to save:** After apply, run `tofu output` and note the values.

### Step 3: Deploy Dev Environment (compute + storage)

```bash
cd aws/environments/dev

# Create terraform.tfvars
cat > terraform.tfvars << 'EOF'
project            = "multicloud-tf"
environment        = "dev"
region             = "us-east-1"
cidr_block         = "10.0.0.0/16"
availability_zone  = "us-east-1a"
ssh_source_cidr    = "<YOUR_IP>/32"
size               = "small"
storage_bucket_name = "multicloud-tf-dev-aws-storage"
public_key_openssh = "ssh-rsa AAAA... user@host"
# image_id = "ami-0c55b159cbfafe1f0"   # optional — omit for latest Ubuntu 22.04
EOF
# Replace <YOUR_IP> with your public IP (find it: curl ifconfig.me)

tofu init -backend-config=backend.tfbackend
tofu plan      # Review carefully!
tofu apply     # Creates VPC, subnets, instance, S3 bucket
```

**Expected resources:**
- VPC + 2 subnets (public/private)
- Internet gateway + route table
- Security group (SSH from your IP only)
- EC2 instance (t3.micro, Ubuntu 22.04)
- S3 bucket (versioned, private)

### Step 4: SSH into Your Instance

```bash
PUBLIC_IP=$(tofu output -raw public_ip)
echo "SSH into: ubuntu@${PUBLIC_IP}"
ssh -i ~/.ssh/id_rsa ubuntu@${PUBLIC_IP}
```

### Repeat for Staging and Prod

```bash
cd ../../environments/staging
# Same terraform.tfvars but with different values:
#   environment = "staging"
#   cidr_block = "10.16.0.0/16"
#   availability_zone = "us-east-1b"
#   storage_bucket_name = "multicloud-tf-staging-aws-storage"

cd ../prod
#   environment = "prod"
#   cidr_block = "10.32.0.0/16"
#   storage_bucket_name = "multicloud-tf-prod-aws-storage"
```

---

## 5. GCP Deployment

### Step 1: Create State Bucket (bootstrap)

```bash
cd gcp/bootstrap

cat > terraform.tfvars << 'EOF'
project        = "multicloud-tf"
gcp_project_id = "<your-gcp-project-id>"
region         = "us-central1"
EOF

tofu init
tofu plan
tofu apply
```

### Step 2: Create IAM Identity

```bash
cd gcp/identity

cat > terraform.tfvars << 'EOF'
project        = "multicloud-tf"
region         = "us-central1"
gcp_project_id = "<your-gcp-project-id>"
EOF

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

### Step 3: Deploy Dev Environment

```bash
cd gcp/environments/dev

cat > terraform.tfvars << 'EOF'
project             = "multicloud-tf"
environment         = "dev"
region              = "us-central1"
gcp_project_id      = "<your-gcp-project-id>"
cidr_block          = "10.1.0.0/16"
ssh_source_cidr     = "<YOUR_IP>/32"
size                = "small"
image               = "debian-cloud/debian-12"
storage_bucket_name = "multicloud-tf-dev-gcp-storage"
public_key_openssh  = "user@host:ssh-rsa AAAA... user@host"
EOF

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

**Note:** GCP e2-micro is always free in US regions (us-central1, us-east1, us-west1).

### Step 4: SSH into Your Instance

```bash
EXTERNAL_IP=$(tofu output -raw external_ip)
echo "SSH into: debian@${EXTERNAL_IP}"
ssh -i ~/.ssh/id_rsa debian@${EXTERNAL_IP}
```

### Repeat for Staging and Prod

```bash
cd ../../environments/staging
# Set environment = "staging"
# cidr_block = "10.17.0.0/16"
# storage_bucket_name = "multicloud-tf-staging-gcp-storage"

cd ../prod
# Set environment = "prod"
# cidr_block = "10.33.0.0/16"
# storage_bucket_name = "multicloud-tf-prod-gcp-storage"
```

---

## 6. OCI Deployment

### Step 1: Create State Bucket (bootstrap)

```bash
cd oci/bootstrap

cat > terraform.tfvars << 'EOF'
project        = "multicloud-tf"
region         = "us-sanjose-1"
compartment_id = "ocid1.compartment.oc1..aaaa..."   # your root tenancy compartment
namespace      = "<your-object-storage-namespace>"   # from `oci os ns get`
EOF

# The OCI provider reads credentials from ~/.oci/config automatically.
# Make sure ~/.oci/config exists first with your API key.

tofu init
tofu plan
tofu apply
```

### Step 2: Create IAM Identity

```bash
cd oci/identity

cat > terraform.tfvars << 'EOF'
project    = "multicloud-tf"
region     = "us-sanjose-1"
tenancy_id = "ocid1.tenancy.oc1..aaaa..."
EOF

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

**Outputs to save:** Run `tofu output` — you'll need `compartment_id` for environments.

### Step 3: Deploy Dev Environment

```bash
cd oci/environments/dev

cat > terraform.tfvars << 'EOF'
project              = "multicloud-tf"
environment          = "dev"
region               = "us-sanjose-1"
cidr_block           = "10.2.0.0/16"
availability_domain  = "US-SANJOSE-1-AD-1"
ssh_source_cidr      = "<YOUR_IP>/32"
compartment_id       = "ocid1.compartment.oc1..aaaa..."   # from identity output
size                 = "small"
image_id             = "ocid1.image.oc1..aaaa..."          # Ubuntu 22.04 OCID
storage_bucket_name  = "multicloud-tf-dev-oci-storage"
public_key_openssh   = "ssh-rsa AAAA... user@host"
EOF
# Replace placeholder values with your actual data

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

**How to find your values:**
- **Availability Domain:** `oci iam availability-domain list --query 'data[].name'`
- **Image OCID:** `oci compute image list --compartment-id <tenancy-ocid> --operating-system "Canonical Ubuntu" --operating-system-version "22.04" --shape "VM.Standard.E2.1.Micro"` — or Console → Compute → Images
- **Compartment OCID:** `tofu output` from the `oci/identity` apply (Section 6, Step 2)

### Step 4: SSH into Your Instance

```bash
PUBLIC_IP=$(tofu output -raw public_ip)
echo "SSH into: opc@${PUBLIC_IP}"
ssh -i ~/.ssh/id_rsa opc@${PUBLIC_IP}
```

### Repeat for Staging and Prod

```bash
cd ../../environments/staging
# Set environment = "staging"
# cidr_block = "10.18.0.0/16"
# compartment_id = <same as dev>
# storage_bucket_name = "multicloud-tf-staging-oci-storage"

cd ../prod
# Set environment = "prod"
# cidr_block = "10.34.0.0/16"
# storage_bucket_name = "multicloud-tf-prod-oci-storage"
```

---

## 7. Phase 3 — Networking & IAM Apply

The networking modules, IAM modules, identity roots, and environment wiring are committed and `tofu validate`-green, but live apply has not been run yet. Follow this once real cloud credentials exist.

### Prerequisites

Same tooling and credentials as Sections 3-6 above. OCI state access uses the `[oci-state]` profile from Section 3 (no env vars needed).

### Identity Apply (per cloud, first)

Apply each cloud's IAM identity **before any environment**: the environment roots depend on identity outputs (OCI `compartment_id`), and the AWS role / GCP service account must exist before resources are created.

For each of `aws/identity`, `gcp/identity`, `oci/identity`:

```bash
cd <cloud>/identity
cp terraform.tfvars.example terraform.tfvars   # then fill the placeholders
tofu init -backend-config=backend.tfbackend
tofu apply
tofu output    # capture the outputs for the next step
```

Per-cloud placeholder fills:

| Cloud | Variable | Fill-in |
|-------|----------|---------|
| AWS | `trust_principal` | Your IAM user/CI ARN, e.g. `arn:aws:iam::123456789012:user/alice` |
| AWS | `region` | `us-east-1` (pre-filled) |
| GCP | `gcp_project_id` | From `gcloud config get-value project` |
| OCI | `tenancy_id` | Your tenancy (root compartment) OCID from the OCI Console |
| OCI | `region` | `us-sanjose-1` (pre-filled) |

Capture from `tofu output`: AWS `role_arn` (plus `role_name`, `policy_arn`); GCP `service_account_email`; OCI `compartment_id` (the project compartment OCID, required by every OCI environment).

### Environment Apply (identity first, then per environment)

For each of the 9 environments, after identity applies, edit the gitignored `{cloud}/environments/{env}/terraform.tfvars` and replace the placeholders:

| Placeholder | Fill-in |
|-------------|---------|
| `ssh_source_cidr` | **Your public IP /32 — NEVER `0.0.0.0/0`**. Current placeholder is TEST-NET-3 `203.0.113.7/32`; find your IP with `curl ifconfig.me` |
| `availability_zone` (AWS) | A real AZ in your region, e.g. `us-east-1a` |
| `availability_domain` (OCI) | A real AD name, e.g. `US-SANJOSE-1-AD-1` |
| `compartment_id` (OCI) | The `compartment_id` output from the `oci/identity` apply |
| `gcp_project_id` (GCP) | Your real GCP project ID |

Then initialize and apply:

```bash
cd <cloud>/environments/<env>
tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

Answer **"no"** if prompted to migrate existing state (nothing to migrate).

### Verification

After each apply:

```bash
tofu plan      # no drift
tofu output    # subnet IDs / role ARNs
```

Optional tooling pass (AWS/GCP only — no OCI ruleset):

```bash
tflint --init && tflint
trivy config .
```

---

## 8. Verify Deployment

After applying all environments, verify:

```bash
# From project root
tofu fmt -check -recursive        # Formatting clean
tofu init -backend=false -validate  # All configs valid

# Check no local state files
find . -name "*.tfstate" -type f   # Should return nothing

# SSH test (repeat for each cloud)
ssh -i ~/.ssh/id_rsa ubuntu@<aws-public-ip> "uname -a"
ssh -i ~/.ssh/id_rsa debian@<gcp-external-ip> "uname -a"
ssh -i ~/.ssh/id_rsa opc@<oci-public-ip> "uname -a"
```

---

## 9. Cleanup / Destroy

To remove all infrastructure (in reverse order):

```bash
# Environments first (destroys servers, storage, networking)
cd aws/environments/prod && tofu destroy
cd aws/environments/staging && tofu destroy
cd aws/environments/dev && tofu destroy

# Identity (destroys IAM resources)
cd aws/identity && tofu destroy

# Bootstrap (destroys state bucket — DO THIS LAST)
cd aws/bootstrap && tofu destroy
```

Repeat for `gcp/` and `oci/`.

**Warning:** `tofu destroy` will permanently delete all resources. Make sure you have backups of any data in storage buckets.

---

## 10. Troubleshooting

### Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `No valid credential sources` | Cloud credentials not configured | Check `aws configure`, `gcloud auth list`, or `~/.oci/config` |
| `failed to refresh cached credentials ... no EC2 IMDS role` | OCI state backend missing credentials | Create `[oci-state]` profile in `~/.aws/credentials` (see Section 3) |
| `Backend initialization required` | Backend changed | Run `tofu init -reconfigure` |
| `Error creating instance` | Insufficient quota | Check free tier limits in cloud console |
| `AccessDenied` | IAM policy missing | Add required policies to your user/group |
| `Name must be unique` | S3 bucket name taken | S3 names are globally unique — add your project prefix |
| `Error: Error initializing backend` | Wrong region or bucket | Verify bucket exists in the region, check `.tfbackend` values |
| `Do you want to migrate existing state?` | First init on fresh bucket | Answer **no** — nothing to migrate |

### Free Tier Limits

| Cloud | Compute | Storage | Notes |
|-------|---------|---------|-------|
| AWS | 750 hrs/mo t3.micro (12-month) | 5 GB S3 | Expires after 12 months |
| GCP | e2-micro always free (US only) | 5 GB GCS | Permanent |
| OCI | 2 OCPU/12 GB ARM (always free) | 10 GB Object Storage | Reduced from 4/24 in June 2026 |

### Debugging

```bash
tofu state list           # Resources in state
tofu state show <resource> # Details of a resource
tofu output               # Output values
TF_LOG=DEBUG tofu plan    # Verbose logging
```

---

## 11. Known Gaps & Notes

- **OCI has NO state locking.** The OCI S3-compatibility endpoint does not support the conditional writes that `use_lockfile` requires, so concurrent applies are not protected. This is accepted for a single-user project.
- **OCI endpoint form to be confirmed at live-init**: the committed `<namespace>.compat.objectstorage.us-sanjose-1.oraclecloud.com` form should be verified against your tenancy/realm on first `tofu init`.
- **`use_lockfile` / `encrypt` / `skip_*` flags are intentional per-cloud choices** — AWS uses S3-native locking + SSE-S3, OCI uses the `skip_*` flags because `us-sanjose-1` is not an AWS region and OCI has no STS/IMDS/account-ID endpoints.
- **There is NO official OCI TFLint ruleset** (`tflint-ruleset-oci` returns 404). Linting covers AWS/GCP only; OCI relies on `tofu validate` alone.
- **`tofu validate` green does not equal deployable** — placeholders that parse cleanly (e.g. `availability_domain = "AD-1"`, `<your-...>` strings, wrong AD names) fail at `tofu apply`. Replace every placeholder before applying.
- **SSH placeholder must be replaced before apply**: `ssh_source_cidr = 203.0.113.7/32` is TEST-NET-3 documentation space; leaving it makes SSH unreachable (safe but broken) — set your real IP /32.
- **Apply order matters**: OCI environments require the `oci/identity` compartment to exist first (its OCID is an input); apply identity first for all clouds so the role/SA exists before Phase 4 consumes it.
- **Credentials never belong in `.tf`/`.tfbackend` files** — always via environment variables, CLI config, or the `[oci-state]` profile. The `.tfbackend` files hold identifiers only, which is why they are committed.

---

## 12. Kubernetes (Coming Soon)

This phase will cover deploying Kubernetes clusters on each cloud:

| Cloud | Managed K8s | Free Tier? |
|-------|-------------|------------|
| AWS | EKS | Control plane ~$0.10/hr |
| GCP | GKE | Autopilot free tier (us-central1) |
| OCI | OKE | Always free (1 cluster, 3 node pools) |

---

*Project: Multi-Cloud Terraform Infrastructure*
