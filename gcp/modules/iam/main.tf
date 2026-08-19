locals {
  common_tags = merge(var.tags, {
    project    = var.project
    managed_by = "opentofu"
  })
}

resource "google_service_account" "project" {
  account_id   = "${var.project}-gcp-sa"
  display_name = "Project service account"
  description  = "Least-privilege service account for project resources (D-23)"
}

# Non-authoritative bindings: google_project_iam_member grants each role to the
# service account without clobbering other project IAM. The authoritative
# project-level IAM policy resource would overwrite ALL roles (lockout risk),
# so it is never used here.
resource "google_project_iam_member" "network_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.networkAdmin"
  member  = google_service_account.project.member
}

resource "google_project_iam_member" "instance_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.project.member
}

resource "google_project_iam_member" "object_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = google_service_account.project.member
}
