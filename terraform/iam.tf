resource "google_project_iam_member" "terraform_network_admin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"

  member = "serviceAccount:terraform-github@mohan-sre-assessment-20261001.iam.gserviceaccount.com"
}
