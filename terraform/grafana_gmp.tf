resource "google_service_account" "gmp_datasource_syncer" {
  account_id   = "gmp-ds-syncer"
  display_name = "Grafana Managed Prometheus Datasource Syncer"
}

resource "google_project_iam_member" "gmp_datasource_syncer_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"

  member = "serviceAccount:${google_service_account.gmp_datasource_syncer.email}"
}

resource "google_service_account_iam_member" "gmp_datasource_syncer_workload_identity" {
  service_account_id = google_service_account.gmp_datasource_syncer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/gmp-ds-syncer]"
}