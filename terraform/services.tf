resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project            = var.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  project            = var.project_id
  service            = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  project            = var.project_id
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "gkehub" {
  project            = var.project_id
  service            = "gkehub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "mcs" {
  project            = var.project_id
  service            = "multiclusterservicediscovery.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "multicluster_ingress" {
  project            = var.project_id
  service            = "multiclusteringress.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "traffic_director" {
  project            = var.project_id
  service            = "trafficdirector.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dns" {
  project            = var.project_id
  service            = "dns.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "resource_manager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "kms" {
  project            = var.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  project            = var.project_id
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}
