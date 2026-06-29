###############################################################################
# Cloud DNS managed zones.
#
# *_compliant -> DNSSEC enabled
# *_legacy    -> DNSSEC off (fail)
###############################################################################

# COMPLIANT: DNSSEC enabled.
resource "google_dns_managed_zone" "public_compliant" {
  name        = "qe-public-zone"
  dns_name    = "quotes.example.com."
  description = "Public zone for the quote engine"

  dnssec_config {
    state = "on"
  }
}

# NON-COMPLIANT: DNSSEC off.
resource "google_dns_managed_zone" "marketing_legacy" {
  name        = "qe-marketing-zone"
  dns_name    = "promo.example.com."
  description = "Marketing zone (DNSSEC disabled)"

  dnssec_config {
    state = "off"
  }
}

# NON-COMPLIANT: no dnssec_config block at all.
resource "google_dns_managed_zone" "internal_legacy" {
  name        = "qe-internal-zone"
  dns_name    = "internal.example.com."
  description = "Internal zone (no DNSSEC)"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.core_compliant.id
    }
  }
}

resource "google_dns_record_set" "api_a" {
  name         = "api.${google_dns_managed_zone.public_compliant.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public_compliant.name
  rrdatas      = ["203.0.113.10"]
}
