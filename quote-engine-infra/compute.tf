###############################################################################
# Compute VMs: bastion + batch rating runners.
#
# *_compliant -> shielded VM, OS login on, no public IP, no serial port,
#                no IP forwarding, custom SA + minimal scopes
# *_legacy    -> the opposite (controls fail)
###############################################################################

# COMPLIANT: shielded VM, OS Login, no public IP, no serial console.
resource "google_compute_instance" "bastion_compliant" {
  name         = "qe-bastion"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_compliant.id
    # No access_config block => no external IP.
  }

  can_ip_forward = false

  metadata = {
    enable-oslogin         = "TRUE"
    serial-port-enable     = "FALSE"
    block-project-ssh-keys = "TRUE"
  }

  service_account {
    email  = google_service_account.quote_app_compliant.email
    scopes = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
  }

  labels = var.labels
}

# COMPLIANT: rating runner, also hardened.
resource "google_compute_instance" "rating_runner_compliant" {
  name         = "qe-rating-runner"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_compliant.id
  }

  can_ip_forward = false

  metadata = {
    enable-oslogin     = "TRUE"
    serial-port-enable = "FALSE"
  }

  service_account {
    email  = google_service_account.rating_worker_compliant.email
    scopes = ["https://www.googleapis.com/auth/pubsub", "https://www.googleapis.com/auth/logging.write"]
  }
}

# NON-COMPLIANT: public IP, OS Login off, serial port on, IP forwarding on,
# default SA with full cloud-platform scope, no shielded VM config.
resource "google_compute_instance" "legacy_jumpbox" {
  name         = "qe-legacy-jumpbox"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_legacy.id
    access_config {
      # Ephemeral public IP.
    }
  }

  can_ip_forward = true

  metadata = {
    enable-oslogin     = "FALSE"
    serial-port-enable = "TRUE"
  }

  # Default compute service account with full API access.
  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# NON-COMPLIANT: legacy batch box, public IP + serial port, project ssh keys.
resource "google_compute_instance" "legacy_batch" {
  name         = "qe-legacy-batch"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_legacy.id
    access_config {}
  }

  can_ip_forward = true

  metadata = {
    serial-port-enable = "TRUE"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# COMPLIANT: encrypted regional disk with CMEK.
resource "google_compute_disk" "data_compliant" {
  name = "qe-data-disk"
  zone = var.zone
  size = 50
  type = "pd-ssd"

  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.database_compliant.id
  }
}

# NON-COMPLIANT: disk without CMEK (Google-managed only).
resource "google_compute_disk" "scratch_legacy" {
  name = "qe-scratch-disk-legacy"
  zone = var.zone
  size = 20
  type = "pd-standard"
}
