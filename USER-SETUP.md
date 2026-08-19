# User Setup — Multi-Cloud Remote State & Environments

> **Phase 2 is config-only.** All backend configs, bootstrap modules, and this runbook are committed to the repo. **Live `tofu init` / `tofu apply` has NOT been run** — this document is the deferred live-verification runbook (decision D-12). Follow it once real cloud credentials exist.

---

## 1. Overview

Phase 2 wires each environment root module to an encrypted, versioned remote state backend and provisions the state buckets via per-cloud Terraform bootstrap modules. The topology is **9 state buckets — one per cloud × environment** (decision D-08): `{aws,gcp,oci} × {dev,staging,prod}`. Each environment stores state in its own bucket for the strongest isolation (prod credentials never touch dev/staging state), using a flat single state key (`terraform.tfstate`).

Backend types per cloud:

| Cloud | Backend | Locking |
|-------|---------|---------|
| AWS   | `s3` (native) | `use_lockfile = true` (S3 conditional writes) |
| GCP   | `gcs` (native) | Native object locking |
| OCI   | `s3` → OCI S3-compat endpoint | **None** (see §8) |

## 2. Prerequisites

- **OpenTofu `>= 1.12.0`** — already installed (verify with `tofu version`).
- Per-cloud CLI (install only the ones you'll use):
  - AWS CLI v2 — `aws`
  - Google Cloud CLI — `gcloud`
  - OCI CLI — `oci`
- **Optional dev tools** (not required for init/apply):
  - `tflint` — linter (uses `.tflint.hcl`)
  - `trivy` — security scanner (`trivy config .`)
  - `terraform-docs` — module README generation

## 3. Credential setup (per cloud)

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

Then create an **OCI Customer Secret Key** (Console → Identity → Users → your user → Customer Secret Keys) and export it as AWS-style credentials for the S3-compatibility API (decision D-18):

```bash
export AWS_ACCESS_KEY_ID="<customer-secret-access-key>"
export AWS_SECRET_ACCESS_KEY="<customer-secret-secret-key>"
```

## 4. Bootstrap (create the 9 buckets)

For each of `aws/bootstrap`, `gcp/bootstrap`, and `oci/bootstrap`:

```bash
cd <cloud>/bootstrap
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and fill the placeholders (see below)
tofu init
tofu apply
tofu output    # list the created bucket names
```

Placeholders to fill per cloud:

- **AWS:** none — `project` and `region` are pre-filled in the example.
- **GCP:** `gcp_project_id` — set to the value from `gcloud config get-value project`.
- **OCI:** `compartment_id` (your compartment OCID) and `namespace` (from `oci os ns get`).

## 5. Backend config placeholder replacement

Replace the placeholders in the environment backend config files **before** first init:

- **GCP:** replace `<project-id>` in `gcp/environments/{dev,staging,prod}/backend.tfbackend` with your real GCP project ID (bucket names must be globally unique — research Pitfall 4).
- **OCI:** replace `<namespace>` in the `endpoints.s3` URL in `oci/environments/{dev,staging,prod}/backend.tfbackend` with the namespace from `oci os ns get` (research assumption A3).

AWS backend config has no placeholders — it is ready as committed.

## 6. Environment init

For each of the 9 environment directories:

```bash
cd {cloud}/environments/{env}
tofu init -backend-config=backend.tfbackend
```

OpenTofu will prompt **"Do you want to migrate existing state?"** — answer **"no"**. The `.terraform/` directory from Phase 1 (`tofu init -backend=false`) contains no resources, so there is nothing to migrate (research Pitfall 3).

> **Note:** the GCP and OCI auth env vars exported in §3 must still be set when you run init.

## 7. Verify

```bash
tofu plan        # should show no changes (main.tf is a placeholder)
tofu state list  # empty — no resources managed yet
```

After installing the optional tools:

```bash
tflint --init && tflint
trivy config .
```

## 8. Notes & known gaps

- **OCI has NO state locking.** The OCI S3-compatibility endpoint does not support the conditional writes that `use_lockfile` requires, so concurrent applies are not protected. This is accepted for a single-user project (decision D-18 / research assumption A2).
- **OCI endpoint form to be confirmed at live-init** (research assumption A3): the committed `<namespace>.compat.objectstorage.<region>.oraclecloud.com` form should be verified against your tenancy/realm on first `tofu init`.
- **`use_lockfile` / `encrypt` / `skip_*` flags are intentional per-cloud choices** — AWS uses S3-native locking + SSE-S3, OCI uses the `skip_*` flags because `ap-tokyo-1` is not an AWS region and OCI has no STS/IMDS/account-ID endpoints.
- **There is NO official OCI TFLint ruleset** (`github.com/terraform-linters/tflint-ruleset-oci` returns 404). Linting therefore covers AWS/GCP only; OCI relies on `tofu validate` alone.
- **Credentials never belong in `.tf`/`.tfbackend` files** — always via environment variables or CLI config. `backend.tfbackend` holds identifiers only, which is why it is committed.

---

## 9. Phase 3 — Networking & IAM apply (deferred)

> This phase is config-only (decision D-19): the networking modules, IAM modules, identity
> roots, and environment wiring are committed and `tofu validate`-green, but **live apply has
> NOT been run**. Follow this runbook once real cloud credentials exist.

### 9.1 Prerequisites

Same tooling and credentials as §2/§3:

- **OpenTofu `>= 1.12.0`** — installed (`tofu version`).
- Per-cloud CLI + credentials per §3: AWS CLI env vars / `aws sso login`; `gcloud auth application-default login`; OCI CLI + `~/.oci/config`.
- **Optional** dev tools: `tflint`, `trivy` (used in §9.4; not required to apply).

### 9.2 Identity apply (per cloud, first)

Apply each cloud's IAM identity **before any environment**: the environment roots depend on
identity outputs (OCI `compartment_id`), and the AWS role / GCP service account must exist
before resources are created (D-23/D-24).

For each of `aws/identity`, `gcp/identity`, `oci/identity`:

```bash
cd <cloud>/identity
cp terraform.tfvars.example terraform.tfvars   # then fill the placeholders below
tofu init
tofu apply
tofu output    # capture the outputs for the next step
```

Per-cloud placeholder fills:

| Cloud | Variable | Fill-in |
|-------|----------|---------|
| AWS | `trust_principal` | Your IAM user/CI ARN that will assume the project role (D-25), e.g. `arn:aws:iam::123456789012:user/alice` |
| AWS | `region` | `us-east-1` (pre-filled) |
| GCP | `gcp_project_id` | From `gcloud config get-value project` |
| OCI | `tenancy_id` | Your tenancy (root compartment) OCID from the OCI Console |
| OCI | `region` | `ap-tokyo-1` (pre-filled) |

Capture from `tofu output`: AWS `role_arn` (plus `role_name`, `policy_arn`); GCP
`service_account_email`; OCI `compartment_id` (the project compartment OCID, required by
every OCI environment).

### 9.3 Environment apply (identity first, then per environment)

For each of the 9 environments, after §9.2 completes, edit the
**gitignored** `{cloud}/environments/{env}/terraform.tfvars` and replace the placeholders:

| Placeholder | Fill-in |
|-------------|---------|
| `ssh_source_cidr` | **Your public IP /32 — NEVER `0.0.0.0/0`** (D-21). Current placeholder is TEST-NET-3 `203.0.113.7/32`; find your IP with `curl ifconfig.me` |
| `availability_zone` (AWS) | A real AZ in your region, e.g. `us-east-1a` (pre-filled placeholder) |
| `availability_domain` (OCI) | A real AD name, e.g. `ap-tokyo-1-AD-1` — the `AD-1` placeholder fails at apply (see §9.5) |
| `compartment_id` (OCI) | The `compartment_id` output from the `oci/identity` apply (§9.2) |
| `gcp_project_id` (GCP) | Your real GCP project ID (region is already set in tfvars) |

Then initialize with the partial backend config and apply:

```bash
cd <cloud>/environments/<env>
tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

Answer **"no"** if prompted to migrate existing state (nothing to migrate — Phase 2 Pitfall 3).

### 9.4 Verification

After each apply:

```bash
tofu plan      # no drift
tofu output    # subnet IDs / role ARNs
```

Optional tooling pass (AWS/GCP only — no OCI ruleset, see §9.5):

```bash
tflint --init && tflint
trivy config .
```

### 9.5 Known gaps

- **No OCI TFLint ruleset** (`tflint-ruleset-oci` returns 404) — OCI relies on `tofu validate` alone.
- **`tofu validate` green ≠ deployable** (Pitfall 7): placeholders that parse cleanly — OCI `availability_domain = "AD-1"`, `<your-...>` strings, wrong AD names, compartment placement — fail at `tofu apply`. Replace every placeholder before applying.
- **SSH placeholder must be replaced before apply**: `ssh_source_cidr = 203.0.113.7/32` is TEST-NET-3 documentation space (D-21); leaving it makes SSH unreachable (safe but broken) — set your real IP /32.
- **Apply order matters**: OCI environments require the `oci/identity` compartment to exist first (its OCID is an input); AWS/GCP environments don't consume identity outputs yet, but apply identity first anyway so the role/SA exists before Phase 4 consumes it.
