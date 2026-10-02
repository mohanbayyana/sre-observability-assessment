resource "google_project_service" "compute" {
  project = "mohan-sre-assessment-20261001"
  service = "compute.googleapis.com"

  disable_on_destroy = false
}
