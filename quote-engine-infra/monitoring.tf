###############################################################################
# Logging, monitoring, secrets and messaging for the quote engine.
###############################################################################

# Secret Manager -------------------------------------------------------------

# COMPLIANT: secret with CMEK + scoped access.
resource "google_secret_manager_secret" "db_password" {
  secret_id = "qe-db-password"

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.database_compliant.id
        }
      }
    }
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_password_v1" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = "demo-not-a-real-password"
}

# NON-COMPLIANT: secret publicly accessible via allUsers.
resource "google_secret_manager_secret_iam_member" "db_password_public" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "allUsers"
}

# COMPLIANT: scoped secret access for the app SA.
resource "google_secret_manager_secret_iam_member" "db_password_app" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}

# Pub/Sub --------------------------------------------------------------------

resource "google_pubsub_topic" "rating_requests_compliant" {
  name = "qe-rating-requests"

  # COMPLIANT: CMEK-encrypted topic.
  kms_key_name = google_kms_crypto_key.database_compliant.id
}

# NON-COMPLIANT: topic without CMEK.
resource "google_pubsub_topic" "events_legacy" {
  name = "qe-events-legacy"
}

resource "google_pubsub_subscription" "rating_worker" {
  name  = "qe-rating-worker-sub"
  topic = google_pubsub_topic.rating_requests_compliant.name
}

# NON-COMPLIANT: topic IAM exposed to allUsers.
resource "google_pubsub_topic_iam_member" "events_public" {
  topic  = google_pubsub_topic.events_legacy.name
  role   = "roles/pubsub.publisher"
  member = "allUsers"
}

# Logging + monitoring -------------------------------------------------------

# COMPLIANT: project-wide log sink to a dedicated bucket.
resource "google_logging_project_sink" "audit_sink" {
  name        = "qe-audit-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.access_logs_compliant.name}"
  filter      = "logName:cloudaudit.googleapis.com"

  unique_writer_identity = true
}

# COMPLIANT: log metric for project ownership changes.
resource "google_logging_metric" "project_ownership_changes" {
  name   = "qe-project-ownership-changes"
  filter = "(protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\") AND (ProjectOwnership OR projectOwnerInvitee)"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_notification_channel" "ops_email" {
  display_name = "Quote Engine Ops"
  type         = "email"

  labels = {
    email_address = "ops@example.com"
  }
}

# COMPLIANT: alert policy bound to the ownership metric.
resource "google_monitoring_alert_policy" "ownership_alert" {
  display_name = "Project ownership changes"
  combiner     = "OR"

  conditions {
    display_name = "Ownership change detected"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.project_ownership_changes.name}\" resource.type=\"global\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.ops_email.id]
}
