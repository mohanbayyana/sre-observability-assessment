data "google_project" "current" {
  project_id = var.project_id
}

resource "google_gke_hub_membership" "primary" {
  membership_id = "gke-primary"
  location      = var.region

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.primary.id}"
    }
  }

  depends_on = [
    google_project_service.gkehub
  ]
}

resource "google_gke_hub_membership" "secondary" {
  membership_id = "gke-secondary"
  location      = var.secondary_region

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.secondary.id}"
    }
  }

  depends_on = [
    google_project_service.gkehub
  ]
}

resource "google_gke_hub_feature" "mcs" {
  name     = "multiclusterservicediscovery"
  location = "global"

  depends_on = [
    google_project_service.mcs,
    google_gke_hub_membership.primary,
    google_gke_hub_membership.secondary
  ]
}

resource "google_gke_hub_feature" "multicluster_gateway" {
  name     = "multiclusteringress"
  location = "global"

  spec {
    multiclusteringress {
      config_membership = google_gke_hub_membership.primary.id
    }
  }

  depends_on = [
    google_project_service.multicluster_ingress,
    google_gke_hub_membership.primary,
    google_gke_hub_membership.secondary,
    google_gke_hub_feature.mcs
  ]
}

resource "google_project_iam_member" "mcs_network_viewer" {
  project = var.project_id
  role    = "roles/compute.networkViewer"

  member = "principal://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/gke-mcs/sa/gke-mcs-importer"
}