resource "google_compute_global_address" "sre_gateway_ip" {
  name    = "sre-global-gateway-ip"
  project = var.project_id
}

resource "google_dns_managed_zone" "sre_zone" {
  name        = "sre-public-zone"
  dns_name    = "${var.domain_name}."
  description = "Public DNS zone for SRE application"

  project = var.project_id

  depends_on = [
    google_project_service.dns
  ]
}

resource "google_dns_record_set" "sre_app" {
  name         = "${var.app_subdomain}.${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.sre_zone.name

  rrdatas = [
    google_compute_global_address.sre_gateway_ip.address
  ]
}
