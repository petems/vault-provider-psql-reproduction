// Ensure VAULT_ADDR and VAULT_TOKEN env vars are set
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "2.13.0"
    }
    postgresql = {
      source  = "hashicorp/postgresql"
      version = "1.7.1"
    }
  }
  required_version = "0.12.24"
}

provider "postgresql" {
  host            = "localhost"
  port            = 5432
  database        = "postgres"
  username        = "postgres"
  password        = "password"
  sslmode         = "disable"
  connect_timeout = 15
}

resource "postgresql_role" "rds_master_user" {
  name     = "rds_master_user"
  login    = true
  password = "mypass"
}

resource "postgresql_role" "myrole" {
  name     = "myrole"
  login    = true
  password = "mypass"
}

resource "vault_mount" "database" {
  path                      = "database"
  type                      = "database"
  default_lease_ttl_seconds = "2592000" # 30 days
  max_lease_ttl_seconds     = "2592000" # 30 days
}

resource "vault_database_secret_backend_connection" "postgres" {
  allowed_roles = ["myrole"]
  backend       = "${vault_mount.database.path}"
  name          = "postgres"

  // Needed as SSL is disabled on postgres Docker container
  verify_connection = false

  postgresql {
    // sslmode=disable needed for the Postgres Go Client
    connection_url = "postgres://postgres:password@database:5432/postgres?sslmode=disable"
  }
}

resource "vault_database_secret_backend_role" "myrole" {
  backend = "${vault_mount.database.path}"
  name    = "myrole"
  db_name = "postgres"

  creation_statements = [
    "RESET ROLE;",
    "GRANT \"myrole\" TO \"rds_master_user\";",
    "CREATE OR REPLACE FUNCTION myfunc AS $$$$ DECLARE obj object; BEGIN do_something(); do_something_else(); END; $$$$ LANGUAGE pgplsql;",
  ]

  depends_on = [
    postgresql_role.myrole,
    postgresql_role.rds_master_user,
  ]

}