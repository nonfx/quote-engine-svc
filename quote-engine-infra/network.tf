###############################################################################
# Networking for the quote-engine backend.
#
# Mixed posture on purpose:
#   *_compliant  -> control passes
#   *_legacy / *_open / *_insecure -> control fails (KICS finding)
###############################################################################

# COMPLIANT: custom network, auto-create subnetworks disabled.
resource "google_compute_network" "core_compliant" {
  name                    = "qe-core-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# NON-COMPLIANT: auto-create subnetworks enabled (default network style).
resource "google_compute_network" "legacy_auto" {
  name                    = "qe-legacy-vpc"
  auto_create_subnetworks = true
}

# COMPLIANT: private Google access on + VPC flow logs configured.
resource "google_compute_subnetwork" "app_compliant" {
  name                     = "qe-app-subnet"
  ip_cidr_range            = "10.10.0.0/20"
  region                   = var.region
  network                  = google_compute_network.core_compliant.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# NON-COMPLIANT: no private google access, no flow logs.
resource "google_compute_subnetwork" "data_legacy" {
  name                     = "qe-data-subnet"
  ip_cidr_range            = "10.20.0.0/20"
  region                   = var.region
  network                  = google_compute_network.core_compliant.id
  private_ip_google_access = false
}

# Secondary subnet for GKE pods/services (compliant config).
resource "google_compute_subnetwork" "gke_compliant" {
  name                     = "qe-gke-subnet"
  ip_cidr_range            = "10.30.0.0/20"
  region                   = var.region
  network                  = google_compute_network.core_compliant.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.40.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.44.0.0/20"
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# COMPLIANT: firewall scoped to internal CIDR, specific ports.
resource "google_compute_firewall" "internal_compliant" {
  name      = "qe-allow-internal"
  network   = google_compute_network.core_compliant.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_ranges = ["10.10.0.0/20"]
}

# NON-COMPLIANT: SSH (22) open to the world.
resource "google_compute_firewall" "ssh_open" {
  name      = "qe-allow-ssh-anywhere"
  network   = google_compute_network.core_compliant.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# NON-COMPLIANT: RDP (3389) open to the world.
resource "google_compute_firewall" "rdp_open" {
  name      = "qe-allow-rdp-anywhere"
  network   = google_compute_network.core_compliant.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# NON-COMPLIANT: all protocols/ports open to the world.
resource "google_compute_firewall" "all_open" {
  name      = "qe-allow-all-ingress"
  network   = google_compute_network.legacy_auto.id
  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# COMPLIANT: SSH allowed only from the IAP forwarding range.
resource "google_compute_firewall" "iap_ssh_compliant" {
  name      = "qe-allow-iap-ssh"
  network   = google_compute_network.core_compliant.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Cloud Router + NAT so private nodes reach the internet (egress only).
resource "google_compute_router" "nat_router" {
  name    = "qe-nat-router"
  region  = var.region
  network = google_compute_network.core_compliant.id
}

resource "google_compute_router_nat" "nat_compliant" {
  name                               = "qe-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Global address for private service access (Cloud SQL peering).
resource "google_compute_global_address" "private_service_range" {
  name          = "qe-private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.core_compliant.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.core_compliant.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}
