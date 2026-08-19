# INSTALL.md — Deploy Your Multi-Cloud Infrastructure

> **Step-by-step guide to deploy servers, storage, and Kubernetes on AWS, GCP, and OCI.**
> This document replaces the per-phase USER-SETUP.md runbooks with a single deployment guide.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [AWS Deployment](#2-aws-deployment)
3. [GCP Deployment](#3-gcp-deployment)
4. [OCI Deployment](#4-oci-deployment)
5. [Verify Deployment](#5-verify-deployment)
6. [Kubernetes (Coming Soon)](#6-kubernetes-coming-soon)
7. [Cleanup / Destroy](#7-cleanup--destroy)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### Install OpenTofu

```bash
# Linux (Debian/Ubuntu)
curl -fsSL https://get.opentofu.org/install | sh

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
pip install oci-cli
```

### Project Structure

```
terraform/
├── aws/
│   ├── bootstrap/          # Creates state buckets (Phase 2)
│   ├── identity/           # IAM role + policy (Phase 3)
│   ├── modules/
│   │   ├── compute/        # EC2 instances (Phase 4)
│   │   ├── networking/     # VPC, subnets, SG (Phase 3)
│   │   └── storage/        # S3 buckets (Phase 4)
│   └── environments/
│       ├── dev/            # Dev environment root
│       ├── staging/        # Staging environment root
│       └── prod/           # Production environment root
├── gcp/                    # Same structure for GCP
├── oci/                    # Same structure for OCI
└── USER-SETUP.md           # Original Phase 2 runbook
```

### Deploy Order

Each cloud follows the same 3-step order:

```
Step 1: bootstrap   → creates state bucket (remote state lives here)
Step 2: identity    → creates IAM identity (compute/storage scoped to this)
Step 3: environments/{dev,staging,prod} → deploys actual infrastructure
```

---

## 2. AWS Deployment

### Step 1: Configure AWS Credentials

**Option A: AWS CLI (recommended for beginners)**

```bash
aws configure
# You'll be prompted for:
#   AWS Access Key ID:      (from IAM console → Security credentials)
#   AWS Secret Access Key:  (shown once when creating the key)
#   Default region name:    us-east-1
#   Default output format:  json
```

**Option B: Environment variables**

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="wJalrX..."
export AWS_DEFAULT_REGION="us-east-1"
```

**Where to get credentials:**
1. Log into AWS Console → IAM → Users → your user → Security credentials
2. Click "Create access key" → select "Command Line Interface"
3. Download the `.csv` file — you won't see the secret key again

### Step 2: Create State Bucket (bootstrap)

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

### Step 3: Create IAM Identity

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

tofu init
tofu plan
tofu apply
```

**Outputs to save:** After apply, run `tofu output` and note the values.

### Step 4: Deploy Dev Environment (compute + storage)

```bash
cd aws/environments/dev

# Create terraform.tfvars
cat > terraform.tfvars << 'EOF'
project           = "multicloud-tf"
region            = "us-east-1"
cidr_block        = "10.0.0.0/16"
availability_zone = "us-east-1a"
ssh_source_cidr   = "<YOUR_IP>/32"
size              = "small"
image_id          = "ami-0c55b159cbfafe1f0"   # Ubuntu 22.04 us-east-1
bucket_name       = "multicloud-tf-dev-aws-storage"
EOF
# Replace <YOUR_IP> with your public IP (find it: curl ifconfig.me)

tofu init
tofu plan      # Review carefully!
tofu apply     # Creates VPC, subnets, instance, S3 bucket
```

**Expected resources:**
- VPC + 2 subnets (public/private)
- Internet gateway + route table
- Security group (SSH from your IP only)
- EC2 instance (t3.micro, Ubuntu 22.04)
- S3 bucket (versioned, private)

### Step 5: SSH into Your Instance

```bash
# Get the public IP from outputs
PUBLIC_IP=$(tofu output -raw public_ip)
echo "SSH into: ubuntu@${PUBLIC_IP}"

# Connect (use the key pair you specified)
ssh -i ~/.ssh/id_rsa ubuntu@${PUBLIC_IP}
```

### Repeat for staging and prod

```bash
cd ../../environments/staging
# Same terraform.tfvars but with different values:
#   cidr_block = "10.16.0.0/16"
#   availability_zone = "us-east-1b"
#   bucket_name = "multicloud-tf-staging-aws-storage"

cd ../prod
#   cidr_block = "10.32.0.0/16"
#   bucket_name = "multicloud-tf-prod-aws-storage"
```

---

## 3. GCP Deployment

### Step 1: Configure GCP Credentials

**Option A: gcloud CLI (recommended)**

```bash
# Authenticate with your Google account
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Create application default credentials (for Terraform)
gcloud auth application-default login
```

**Option B: Service account key**

```bash
# Create a service account
gcloud iam service-accounts create terraform \
  --display-name="Terraform Admin"

# Grant roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create key.json \
  --iam-account=terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/key.json"
```

**Where to find your Project ID:**
1. Go to console.cloud.google.com
2. Select your project (or create one)
3. The Project ID is shown in the dashboard or under "Project info"

### Step 2: Create State Bucket (bootstrap)

```bash
cd gcp/bootstrap

cat > terraform.tfvars << 'EOF'
project = "multicloud-tf"
region  = "us-central1"
gcp_project_id = "your-gcp-project-id"
EOF

tofu init
tofu plan
tofu apply
```

### Step 3: Create IAM Identity

```bash
cd gcp/identity

cat > terraform.tfvars << 'EOF'
project        = "multicloud-tf"
region         = "us-central1"
gcp_project_id = "your-gcp-project-id"
EOF

tofu init
tofu plan
tofu apply
```

### Step 4: Deploy Dev Environment

```bash
cd gcp/environments/dev

cat > terraform.tfvars << 'EOF'
project        = "multicloud-tf"
region         = "us-central1"
gcp_project_id = "your-gcp-project-id"
cidr_block     = "10.1.0.0/16"
ssh_source_cidr = "<YOUR_IP>/32"
size           = "small"
image          = "debian-cloud/debian-12"
bucket_name    = "multicloud-tf-dev-gcp-storage"
EOF

tofu init
tofu plan
tofu apply
```

**Note:** GCP e2-micro is always free in US regions (us-central1, us-east1, us-west1).

### Step 5: SSH into Your Instance

```bash
EXTERNAL_IP=$(tofu output -raw external_ip)
echo "SSH into: debian@${EXTERNAL_IP}"

# GCP uses OS Login or metadata-based SSH
# If using metadata SSH (default for this project):
ssh -i ~/.ssh/id_rsa debian@${EXTERNAL_IP}
```

### Repeat for staging and prod

```bash
cd ../../environments/staging
# cidr_block = "10.17.0.0/16"
# bucket_name = "multicloud-tf-staging-gcp-storage"

cd ../prod
# cidr_block = "10.33.0.0/16"
# bucket_name = "multicloud-tf-prod-gcp-storage"
```

---

## 4. OCI Deployment

### Step 1: Configure OCI Credentials

**Option A: OCI CLI config (recommended)**

```bash
oci setup config
# Prompts for:
#   Tenancy OCID:     (from console → Administration → Tenancy details)
#   User OCID:         (from console → Identity → Users → your user)
#   Region:            ap-tokyo-1 (or your preferred region)
#   Fingerprint:       (from API key fingerprint)
#   Key file path:     ~/.oci/oci_api_key.pem
```

**Option B: Manual config**

Create `~/.oci/config`:

```ini
[DEFAULT]
tenancy = ocid1.tenancy.oc1..aaaa...
user = ocid1.user.oc1..aaaa...
fingerprint = aa:bb:cc:dd:...
key_file = ~/.oci/oci_api_key.pem
region = ap-tokyo-1
```

**Where to get these values:**
1. Tenancy OCID: Console → Administration → Tenancy Details → OCID
2. User OCID: Console → Identity → Users → click your user → OCID
3. Generate an API key:
   ```bash
   openssl genrsa -out ~/.oci/oci_api_key.pem 2048
   openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
   ```
4. Upload the public key: Console → Identity → Users → your user → API Keys → Add API Key
5. Copy the fingerprint shown after upload

**Required IAM policies:**

Your OCI user needs policies in the root tenancy compartment:
```
Allow group <your-group> to manage all-resources in tenancy
```
Or more restrictive (recommended):
```
Allow group <your-group> to manage virtual-network-family in tenancy
Allow group <your-group> to manage instance-family in tenancy
Allow group <your-group> to manage volume-family in tenancy
Allow group <your-group> to manage object-family in tenancy
Allow group <your-group> to manage compartment in tenancy
```

### Step 2: Create State Bucket (bootstrap)

```bash
cd oci/bootstrap

cat > terraform.tfvars << 'EOF'
project = "multicloud-tf"
region  = "ap-tokyo-1"
EOF

tofu init
tofu plan
tofu apply
```

### Step 3: Create IAM Identity

```bash
cd oci/identity

cat > terraform.tfvars << 'EOF'
project    = "multicloud-tf"
region     = "ap-tokyo-1"
tenancy_id = "ocid1.tenancy.oc1..aaaa..."
EOF

tofu init
tofu plan
tofu apply
```

**Outputs to save:** Run `tofu output` — you'll need `compartment_id` for environments.

### Step 4: Deploy Dev Environment

```bash
cd oci/environments/dev

cat > terraform.tfvars << 'EOF'
project            = "multicloud-tf"
region             = "ap-tokyo-1"
cidr_block         = "10.2.0.0/16"
availability_domain = "IJuK:AP-TOKYO-1-AD-1"
ssh_source_cidr    = "<YOUR_IP>/32"
compartment_id     = "ocid1.compartment.oc1..aaaa..."   # from identity output
size               = "small"
image              = "ocid1.image.oc1..aaaa..."          # Ubuntu 22.04 OCID
bucket_name        = "multicloud-tf-dev-oci-storage"
namespace          = "your-namespace"                     # from Object Storage settings
EOF
# Replace placeholder values with your actual data

tofu init
tofu plan
tofu apply
```

**How to find your values:**
- **Availability Domain:** `oci iam availability-domain list --query 'data[].name'`
- **Image OCID:** Console → Compute → Custom Images → or use Oracle-provided images
- **Namespace:** Console → Object Storage → Settings → namespace

### Step 5: SSH into Your Instance

```bash
PRIVATE_IP=$(tofu output -raw private_ip)
PUBLIC_IP=$(tofu output -raw public_ip)
echo "SSH into: opc@${PUBLIC_IP}"

ssh -i ~/.ssh/id_rsa opc@${PUBLIC_IP}
```

### Repeat for staging and prod

```bash
cd ../../environments/staging
# cidr_block = "10.18.0.0/16"
# bucket_name = "multicloud-tf-staging-oci-storage"

cd ../prod
# cidr_block = "10.34.0.0/16"
# bucket_name = "multicloud-tf-prod-oci-storage"
```

---

## 5. Verify Deployment

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

## 6. Kubernetes (Coming Soon)

This phase will cover deploying Kubernetes clusters on each cloud:

| Cloud | Managed K8s | Free Tier? |
|-------|-------------|------------|
| AWS | EKS | Control plane ~$0.10/hr |
| GCP | GKE | Autopilot free tier (us-central1) |
| OCI | OKE | Always free (1 cluster, 3 node pools) |

And deploying Prometheus/Grafana for monitoring:

| Component | Purpose | Deployment |
|-----------|---------|------------|
| Prometheus | Metrics collection & alerting | Helm chart on K8s |
| Grafana | Dashboards & visualization | Helm chart on K8s |

**Planned architecture:**
```
Kubernetes Cluster (per cloud)
├── monitoring namespace
│   ├── prometheus-server
│   ├── grafana
│   └── alertmanager
├── app namespace
│   └── (your workloads)
```

Stay tuned — this will be planned as a new GSD phase.

---

## 7. Cleanup / Destroy

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

## 8. Troubleshooting

### Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `Error: No valid credential sources` | Cloud credentials not configured | Check `~/.aws/config`, `gcloud auth list`, or `~/.oci/config` |
| `Error: Backend initialization required` | Backend changed | Run `tofu init -reconfigure` |
| `Error: Error creating instance` | Insufficient quota | Check free tier limits in cloud console |
| `Error: AccessDenied` | IAM policy missing | Add required policies to your user/group |
| `Error: Name must be unique` | S3 bucket name taken | S3 names are globally unique — add your project prefix |
| `tofu validate fails` | Config syntax error | Run `tofu fmt -recursive` first, then check variable values |

### Free Tier Limits

| Cloud | Compute | Storage | Notes |
|-------|---------|---------|-------|
| AWS | 750 hrs/mo t3.micro (12-month) | 5 GB S3 | Expires after 12 months |
| GCP | e2-micro always free (US only) | 5 GB GCS | Permanent |
| OCI | 2 OCPU/12 GB ARM (always free) | 10 GB Object Storage | Reduced from 4/24 in June 2026 |

### Getting Help

```bash
# Check current state
tofu state list           # Resources in state
tofu state show <resource> # Details of a resource
tofu output               # Output values

# Debug provider issues
TF_LOG=DEBUG tofu plan    # Verbose logging
```

---

*Last updated: 2026-08-19*
*Project: Multi-Cloud Terraform Infrastructure*
