###############################################################################
# BigQuery datasets for quote analytics.
#
# *_compliant -> CMEK + scoped access
# *_legacy    -> public dataset (allUsers / allAuthenticatedUsers) (fail)
###############################################################################

# COMPLIANT: CMEK-encrypted dataset, no public access.
resource "google_bigquery_dataset" "analytics_compliant" {
  dataset_id    = "qe_analytics"
  friendly_name = "Quote analytics"
  location      = "US"

  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.database_compliant.id
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.quote_app_compliant.email
  }

  access {
    role          = "READER"
    group_by_email = "platform-team@example.com"
  }

  labels = var.labels
}

# PARTIALLY-COMPLIANT: no longer public (scoped to a group), but still missing
# CMEK default encryption (MEDIUM finding remains).
resource "google_bigquery_dataset" "public_legacy" {
  dataset_id = "qe_public_legacy"
  location   = "US"

  access {
    role           = "READER"
    group_by_email = "platform-team@example.com"
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.legacy_admin.email
  }
}

# PARTIALLY-COMPLIANT: scoped to the app service account instead of allUsers.
resource "google_bigquery_dataset_iam_member" "exports_public" {
  dataset_id = google_bigquery_dataset.public_legacy.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}

# COMPLIANT: scoped table access for the app SA.
resource "google_bigquery_dataset_iam_member" "analytics_app_reader" {
  dataset_id = google_bigquery_dataset.analytics_compliant.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}

resource "google_bigquery_table" "quotes_fact" {
  dataset_id          = google_bigquery_dataset.analytics_compliant.dataset_id
  table_id            = "quotes_fact"
  deletion_protection = false

  schema = <<-EOF
  [
    {"name": "quote_id", "type": "STRING", "mode": "REQUIRED"},
    {"name": "premium",  "type": "NUMERIC", "mode": "NULLABLE"},
    {"name": "created",  "type": "TIMESTAMP", "mode": "NULLABLE"}
  ]
  EOF
}
