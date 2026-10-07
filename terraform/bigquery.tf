resource "google_project_iam_member" "terraform_kms_admin" {
  # checkov:skip=CKV_GCP_42:Terraform deployment service account requires KMS administration to provision and manage CMEK resources

  project = var.project_id
  role    = "roles/cloudkms.admin"

  member = "serviceAccount:terraform-github@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_kms_key_ring" "bigquery" {
  name     = "sre-bigquery-keyring"
  project  = var.project_id
  location = "us"

  depends_on = [
    google_project_service.kms,
    google_project_iam_member.terraform_kms_admin
  ]
}

resource "google_kms_crypto_key" "bigquery" {
  name            = "sre-bigquery-key"
  key_ring        = google_kms_key_ring.bigquery.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "bigquery_encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.bigquery.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:bq-${data.google_project.current.number}@bigquery-encryption.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"

  member = "serviceAccount:terraform-github@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_bigquery_dataset" "sre_logs" {
  # checkov:skip=CKV_GCP_81:Dataset uses Cloud KMS CMEK through default_encryption_configuration

  dataset_id = "sre_logs"
  project    = var.project_id
  location   = "US"

  delete_contents_on_destroy = true

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.bigquery.id
  }

  depends_on = [
    google_kms_crypto_key_iam_member.bigquery_encrypter_decrypter,
    google_project_iam_member.terraform_bigquery_user
  ]
}

resource "google_project_iam_member" "terraform_logging_config_writer" {
  project = var.project_id
  role    = "roles/logging.configWriter"

  member = "serviceAccount:terraform-github@${var.project_id}.iam.gserviceaccount.com"
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

  depends_on = [
    google_project_iam_member.terraform_logging_config_writer
  ]
}

resource "google_bigquery_dataset_iam_member" "sre_logs_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.sre_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.sre_app_logs.writer_identity
}
