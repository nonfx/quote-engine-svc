###############################################################################
# GCS buckets for policy documents, exports, and Terraform state.
#
# *_compliant -> logging + versioning + uniform access + CMEK, private
# *_legacy    -> logging off, versioning off, public, fine-grained (fail)
###############################################################################

# COMPLIANT: versioning + access logging + uniform bucket-level access + CMEK.
resource "google_storage_bucket" "documents_compliant" {
  name                        = "qe-policy-documents-compliant"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket = google_storage_bucket.access_logs_compliant.name
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_compliant.id
  }

  labels = var.labels
}

# COMPLIANT: dedicated log sink bucket (also uniform + versioned).
resource "google_storage_bucket" "access_logs_compliant" {
  name                        = "qe-access-logs-compliant"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }
}

# COMPLIANT: terraform state bucket, hardened.
resource "google_storage_bucket" "tfstate_compliant" {
  name                        = "qe-tfstate-compliant"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket = google_storage_bucket.access_logs_compliant.name
  }
}

# NON-COMPLIANT: no logging, no versioning, fine-grained ACLs, public allowed.
resource "google_storage_bucket" "exports_legacy" {
  name                        = "qe-quote-exports-legacy"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = false
  public_access_prevention    = "inherited"
}

# NON-COMPLIANT: scratch bucket, no versioning / logging, fine-grained.
resource "google_storage_bucket" "scratch_legacy" {
  name                        = "qe-scratch-legacy"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = false
}

# NON-COMPLIANT: grants allUsers read on the exports bucket (anonymous/public).
resource "google_storage_bucket_iam_member" "exports_public" {
  bucket = google_storage_bucket.exports_legacy.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# NON-COMPLIANT: grants allAuthenticatedUsers on scratch bucket.
resource "google_storage_bucket_iam_member" "scratch_public_auth" {
  bucket = google_storage_bucket.scratch_legacy.name
  role   = "roles/storage.objectViewer"
  member = "allAuthenticatedUsers"
}

# COMPLIANT: object viewer bound to the app service account only.
resource "google_storage_bucket_iam_member" "documents_app_reader" {
  bucket = google_storage_bucket.documents_compliant.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}
