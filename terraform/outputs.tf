output "vpc_name" {
  description = "Name of the GKE VPC"
  value       = google_compute_network.gke_vpc.name
}

output "vpc_id" {
  description = "ID of the GKE VPC"
  value       = google_compute_network.gke_vpc.id
}

output "subnet_name" {
  description = "Name of the primary GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "subnet_id" {
  description = "ID of the primary GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "subnet_region" {
  description = "Region of the primary GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.region
}

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}
