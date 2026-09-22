resource "google_compute_network" "vpc" {
  name                    = "terragoat-${var.environment}-network"
  description             = "Virtual vulnerable-by-design network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public-subnetwork" {
  name          = "terragoat-${var.environment}-public-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_firewall" "allow_all" {
  name          = "terragoat-${var.environment}-firewall"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = var.firewall_source_ranges
  target_tags   = ["terragoat-${var.environment}-ssh"]
  allow {
    protocol = "tcp"
    ports    = var.firewall_allowed_tcp_ports
  }
}
