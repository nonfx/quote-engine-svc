###############################################################################
# KMS key rings + crypto keys for encrypting quotes data at rest.
#
# *_compliant -> rotation period set (<= 90 days)
# *_legacy    -> no rotation / rotation too long (fail)
###############################################################################

resource "google_kms_key_ring" "primary" {
  name     = "qe-keyring"
  location = var.region
}

# COMPLIANT: 90-day rotation.
resource "google_kms_crypto_key" "storage_compliant" {
  name            = "qe-storage-key"
  key_ring        = google_kms_key_ring.primary.id
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# COMPLIANT: 30-day rotation for database key.
resource "google_kms_crypto_key" "database_compliant" {
  name            = "qe-database-key"
  key_ring        = google_kms_key_ring.primary.id
  rotation_period = "2592000s" # 30 days
}

# NON-COMPLIANT: no rotation_period set at all.
resource "google_kms_crypto_key" "exports_legacy" {
  name     = "qe-exports-key-legacy"
  key_ring = google_kms_key_ring.primary.id
}

# NON-COMPLIANT: rotation period far longer than 90 days (~1 year).
resource "google_kms_crypto_key" "archive_legacy" {
  name            = "qe-archive-key-legacy"
  key_ring        = google_kms_key_ring.primary.id
  rotation_period = "31536000s" # 365 days
}

# NON-COMPLIANT: crypto key publicly accessible via allUsers.
resource "google_kms_crypto_key_iam_member" "exports_key_public" {
  crypto_key_id = google_kms_crypto_key.exports_legacy.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "allUsers"
}

# COMPLIANT: key access bound to the app SA only.
resource "google_kms_crypto_key_iam_member" "storage_key_app" {
  crypto_key_id = google_kms_crypto_key.storage_compliant.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}
