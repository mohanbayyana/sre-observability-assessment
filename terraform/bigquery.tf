resource "google_bigquery_dataset" "sre_logs" {
  dataset_id = "sre_logs"
  project    = var.project_id
  location   = "US"

  delete_contents_on_destroy = true
}

resource "google_logging_project_sink" "sre_app_logs" {
  name        = "sre-app-logs-to-bigquery"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.sre_logs.dataset_id}"

  filter = <<EOT
resource.type="k8s_container"
resource.labels.namespace_name="sre-app"
EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_iam_member" "sre_logs_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.sre_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.sre_app_logs.writer_identity
}
