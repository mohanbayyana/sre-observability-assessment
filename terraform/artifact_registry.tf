resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app_images" {
  #checkov:skip=CKV_GCP_84:Google-managed encryption is acceptable for this assessment; CMEK is out of scope.

  project       = var.project_id
  location      = var.region
  repository_id = "app-images"
  description   = "Container images for SRE observability assessment"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifact_registry
  ]
}

resource "google_project_iam_member" "terraform_artifact_registry_admin" {
  #checkov:skip=CKV_GCP_42:Terraform provisioning identity requires Artifact Registry administration to create and manage repositories.

  project = var.project_id
  role    = "roles/artifactregistry.admin"

  member = "serviceAccount:terraform-github@${var.project_id}.iam.gserviceaccount.com"
}