data "google_compute_zones" "zones" {}

resource "google_service_account" "server" {
  account_id   = "terragoat-${var.environment}-server"
  display_name = "Least privilege service account for the terragoat server instance"
}

resource "google_compute_instance" "server" {
  machine_type = "n1-standard-1"
  name         = "terragoat-${var.environment}-machine"
  zone         = data.google_compute_zones.zones.names[0]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
    auto_delete = true
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public-subnetwork.name
  }
  can_ip_forward = false

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.server.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    block-project-ssh-keys = true
    enable-oslogin         = true
    serial-port-enable     = false
  }
  labels = {
    git_commit           = "2bdc0871a5f4505be58244029cc6485d45d7bb8e"
    git_file             = "terraform__gcp__instances_tf"
    git_last_modified_at = "2022-01-19-17-02-27"
    git_last_modified_by = "jameswoolfenden"
    git_modifiers        = "jameswoolfenden__nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "cd562b76-fbce-4e60-8c75-c9f43d7ffc16"
  }
}

resource "google_compute_disk" "unencrypted_disk" {
  name = "terragoat-${var.environment}-disk"
  labels = {
    git_commit           = "2bdc0871a5f4505be58244029cc6485d45d7bb8e"
    git_file             = "terraform__gcp__instances_tf"
    git_last_modified_at = "2022-01-19-17-02-27"
    git_last_modified_by = "jameswoolfenden"
    git_modifiers        = "jameswoolfenden__nimrodkor"
    git_org              = "bridgecrewio"
    git_repo             = "terragoat"
    yor_trace            = "bf87b7d7-a9d8-4f03-a0d4-8a4cbb647d03"
  }
}