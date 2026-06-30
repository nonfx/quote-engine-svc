###############################################################################
# Service accounts and IAM bindings.
#
# *_compliant  -> least-privilege role bound to a service account/group
# *_legacy     -> primitive/admin roles, user members, token creator (fail)
###############################################################################

# Service accounts -----------------------------------------------------------

resource "google_service_account" "quote_app_compliant" {
  account_id   = "qe-app"
  display_name = "Quote Engine application"
}

resource "google_service_account" "gke_node_compliant" {
  account_id   = "qe-gke-node"
  display_name = "Quote Engine GKE nodes"
}

resource "google_service_account" "rating_worker_compliant" {
  account_id   = "qe-rating-worker"
  display_name = "Quote Engine rating worker"
}

resource "google_service_account" "legacy_admin" {
  account_id   = "qe-legacy-admin"
  display_name = "Legacy admin (over-privileged)"
}

# Least-privilege bindings (COMPLIANT) --------------------------------------

# COMPLIANT: narrow role bound to a service account.
resource "google_project_iam_member" "app_logwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}

# COMPLIANT: narrow role bound to a service account.
resource "google_project_iam_member" "app_metricwriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.quote_app_compliant.email}"
}

# COMPLIANT: role granted to a Google group, not an individual user.
resource "google_project_iam_member" "platform_group_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "group:platform-team@example.com"
}

# COMPLIANT: narrow role for rating worker.
resource "google_project_iam_member" "rating_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.rating_worker_compliant.email}"
}

# Over-privileged / misconfigured bindings (NON-COMPLIANT) ------------------

# NON-COMPLIANT: primitive owner role.
resource "google_project_iam_member" "legacy_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.legacy_admin.email}"
}

# NON-COMPLIANT: primitive editor role.
resource "google_project_iam_member" "legacy_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.legacy_admin.email}"
}

# NON-COMPLIANT: role granted directly to an individual user.
resource "google_project_iam_member" "user_direct_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "user:contractor@example.com"
}

# PARTIALLY-COMPLIANT: dropped the token-creator escalation path; narrowed to a
# read-only viewer role (the broad owner/editor bindings above remain as MEDIUM).
resource "google_project_iam_member" "legacy_token_creator" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.legacy_admin.email}"
}

# NON-COMPLIANT: service account user role granted broadly.
resource "google_project_iam_member" "legacy_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "user:contractor@example.com"
}

# NON-COMPLIANT: user-managed service account key (long-lived credential).
resource "google_service_account_key" "legacy_admin_key" {
  service_account_id = google_service_account.legacy_admin.name
}

# NON-COMPLIANT: SA-level binding granting token creator to allUsers.
resource "google_service_account_iam_member" "app_sa_public_token" {
  service_account_id = google_service_account.quote_app_compliant.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "allUsers"
}
