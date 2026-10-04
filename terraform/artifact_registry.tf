resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# checkov:skip=CKV_GCP_84: Google-managed encryption is acceptable for this assessment; CMEK is out of scope.
resource "google_artifact_registry_repository" "app_images" {
  project       = var.project_id
  location      = var.region
  repository_id = "app-images"
  description   = "Container images for SRE observability assessment"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifact_registry
  ]
}

# checkov:skip=CKV_GCP_42: This is the Terraform provisioning identity and requires repository administration to create/manage Artifact Registry.
resource "google_project_iam_member" "terraform_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"

  member = "serviceAccount:terraform-github@${var.project_id}.iam.gserviceaccount.com"
}