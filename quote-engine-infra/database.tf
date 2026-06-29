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

# NON-COMPLIANT: public IP, open to 0.0.0.0/0, SSL not required, no backups.
resource "google_sql_database_instance" "rating_legacy" {
  name                = "qe-rating-db-legacy"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = false

      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = false
    }
  }
}

# NON-COMPLIANT: analytics replica, public IP + SSL off (no backup block).
resource "google_sql_database_instance" "analytics_legacy" {
  name                = "qe-analytics-db-legacy"
  database_version    = "POSTGRES_13"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = false
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

# COMPLIANT: password sourced from a secret, not inline.
resource "google_sql_user" "quotes_app" {
  name     = "quotes_app"
  instance = google_sql_database_instance.quotes_compliant.name
  password = google_secret_manager_secret_version.db_password_v1.secret_data
}
