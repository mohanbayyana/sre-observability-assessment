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

output "secondary_region" {
  value = var.secondary_region
}

output "secondary_gke_cluster_name" {
  value = google_container_cluster.secondary.name
}

output "sre_gateway_static_ip" {
  description = "Reserved global static IP for the GKE Gateway"
  value       = google_compute_global_address.sre_gateway_ip.address
}

output "sre_dns_name" {
  description = "Public DNS name for the SRE application"
  value       = "${var.app_subdomain}.${var.domain_name}"
}

output "cloud_dns_name_servers" {
  description = "Cloud DNS name servers to configure at the domain registrar"
  value       = google_dns_managed_zone.sre_zone.name_servers
}
