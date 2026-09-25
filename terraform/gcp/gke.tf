data "google_compute_zones" "available_zones" {
  project = var.project
  region  = var.region
}

resource "google_service_account" "cluster_nodes" {
  account_id   = "terragoat-${var.environment}-nodes"
  display_name = "terragoat-${var.environment} GKE node pool"
}

resource "google_container_cluster" "workload_cluster" {
  name               = "terragoat-${var.environment}-cluster"
  logging_service    = "logging.googleapis.com/kubernetes"
  location           = var.region
  initial_node_count = 1

  enable_legacy_abac       = false
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  remove_default_node_pool = true
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.public-subnetwork.name

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
}

resource "google_container_node_pool" "custom_node_pool" {
  cluster  = google_container_cluster.workload_cluster.name
  location = var.region

  node_config {
    image_type      = "Ubuntu"
    service_account = google_service_account.cluster_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
