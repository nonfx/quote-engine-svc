###############################################################################
# Cloud SQL instances backing quotes, policies and rating data.
#
# *_compliant -> SSL required, private IP, backups + PITR on
# *_legacy    -> SSL off, public IP, no backups (controls fail)
###############################################################################

# COMPLIANT: private IP only, SSL required, backups + binary logging on.
resource "google_sql_database_instance" "quotes_compliant" {
  name                = "qe-quotes-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-custom-2-7680"
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.core_compliant.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "02:00"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
  }
}

# COMPLIANT: policies DB, also private + SSL + backups.
resource "google_sql_database_instance" "policies_compliant" {
  name                = "qe-policies-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-custom-2-7680"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.core_compliant.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }
  }
}

# PARTIALLY-COMPLIANT: private IP + SSL required (no public exposure), but still
# no backups / no PITR and deletion protection off (MEDIUM/LOW findings remain).
resource "google_sql_database_instance" "rating_legacy" {
  name                = "qe-rating-db-legacy"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-n1-standard-1"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.core_compliant.id
      require_ssl     = true
    }

    backup_configuration {
      enabled = false
    }
  }
}

# PARTIALLY-COMPLIANT: private IP + SSL required, but no backup block and
# deletion protection off (MEDIUM/LOW findings remain).
resource "google_sql_database_instance" "analytics_legacy" {
  name                = "qe-analytics-db-legacy"
  database_version    = "POSTGRES_13"
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.core_compliant.id
      require_ssl     = true
    }
  }
}

resource "google_sql_database" "quotes" {
  name     = "quotes"
  instance = google_sql_database_instance.quotes_compliant.name
}

resource "google_sql_database" "policies" {
  name     = "policies"
  instance = google_sql_database_instance.policies_compliant.name
}

# COMPLIANT: password sourced from a secret, not inline. The value is a
# Secret Manager reference, not a literal; KICS's generic-password regex flags
# the assignment as a false positive, so suppress it on this line only.
resource "google_sql_user" "quotes_app" {
  name     = "quotes_app"
  instance = google_sql_database_instance.quotes_compliant.name
  # kics-scan ignore-line
  password = google_secret_manager_secret_version.db_password_v1.secret_data
}
