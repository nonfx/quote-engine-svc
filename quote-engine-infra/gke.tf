###############################################################################
# GKE clusters running the quote-engine API and rating workers.
#
# qe_primary_compliant -> hardened cluster (controls pass)
# qe_legacy_insecure   -> intentionally weak cluster (controls fail)
###############################################################################

# COMPLIANT: private cluster, network policy on, shielded nodes, no legacy ABAC,
# no basic auth / client cert.
resource "google_container_cluster" "qe_primary_compliant" {
  name     = "qe-primary"
  location = var.region
  network  = google_compute_network.core_compliant.id

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.10.0.0/20"
      display_name = "internal"
    }
  }

  enable_legacy_abac = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

# COMPLIANT node pool: shielded nodes, secure boot, integrity monitoring,
# auto-repair/upgrade, no default SA + minimal scopes.
resource "google_container_node_pool" "qe_primary_pool_compliant" {
  name       = "qe-primary-pool"
  location   = var.region
  cluster    = google_container_cluster.qe_primary_compliant.name
  node_count = 2

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = "e2-standard-4"
    service_account = google_service_account.gke_node_compliant.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = var.labels
  }
}

# NON-COMPLIANT: public cluster, network policy off, legacy ABAC on,
# basic auth + client cert issued, no shielded nodes block.
resource "google_container_cluster" "qe_legacy_insecure" {
  name               = "qe-legacy"
  location           = var.zone
  network            = google_compute_network.legacy_auto.id
  initial_node_count = 1

  network_policy {
    enabled = false
  }

  enable_legacy_abac = true

  master_auth {
    username = "admin"
    password = "ChangeMe-Demo-123!"

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# NON-COMPLIANT node pool: no auto-repair/upgrade, no shielded config,
# uses default service account.
resource "google_container_node_pool" "qe_legacy_pool_insecure" {
  name       = "qe-legacy-pool"
  location   = var.zone
  cluster    = google_container_cluster.qe_legacy_insecure.name
  node_count = 1

  management {
    auto_repair  = false
    auto_upgrade = false
  }

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
