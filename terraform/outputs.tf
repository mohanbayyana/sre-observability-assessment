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