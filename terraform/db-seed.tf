# ---------------------------------------------------------------------------
# One-time schema seeding for the 3 RDS instances. RDS is private
# (publicly_accessible = false), so this has to run from inside the VPC —
# a Kubernetes Job on the cluster is the simplest way to do that without a
# bastion host, and keeps the whole thing inside `terraform apply` instead
# of a manual "someone runs psql by hand" step.
# ---------------------------------------------------------------------------
locals {
  auth_init_sql = <<-SQL
    ${file("${path.module}/../auth-service/db/init.sql")}

    INSERT INTO api_keys (name, key_hash)
    VALUES ('evaluation-service', '${sha256(random_password.evaluation_service_api_key.result)}')
    ON CONFLICT (key_hash) DO NOTHING;
  SQL

  flag_init_sql      = file("${path.module}/../flag-service/db/init.sql")
  targeting_init_sql = file("${path.module}/../targeting-service/db/init.sql")
}

resource "kubernetes_config_map" "auth_init_sql" {
  metadata {
    name      = "auth-init-sql"
    namespace = kubernetes_namespace.services["auth-service"].metadata[0].name
  }

  data = {
    "init.sql" = local.auth_init_sql
  }
}

resource "kubernetes_config_map" "flag_init_sql" {
  metadata {
    name      = "flag-init-sql"
    namespace = kubernetes_namespace.services["flag-service"].metadata[0].name
  }

  data = {
    "init.sql" = local.flag_init_sql
  }
}

resource "kubernetes_config_map" "targeting_init_sql" {
  metadata {
    name      = "targeting-init-sql"
    namespace = kubernetes_namespace.services["targeting-service"].metadata[0].name
  }

  data = {
    "init.sql" = local.targeting_init_sql
  }
}

resource "kubernetes_job_v1" "seed_auth_db" {
  metadata {
    name      = "seed-auth-db-${substr(sha1(local.auth_init_sql), 0, 8)}"
    namespace = kubernetes_namespace.services["auth-service"].metadata[0].name
  }

  spec {
    backoff_limit = 2

    template {
      metadata {
        labels = { job = "seed-auth-db" }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["sh", "-c", "psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"]

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.auth_service.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }

        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map.auth_init_sql.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}

resource "kubernetes_job_v1" "seed_flag_db" {
  metadata {
    name      = "seed-flag-db-${substr(sha1(local.flag_init_sql), 0, 8)}"
    namespace = kubernetes_namespace.services["flag-service"].metadata[0].name
  }

  spec {
    backoff_limit = 2

    template {
      metadata {
        labels = { job = "seed-flag-db" }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["sh", "-c", "psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"]

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.flag_service.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }

        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map.flag_init_sql.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}

resource "kubernetes_job_v1" "seed_targeting_db" {
  metadata {
    name      = "seed-targeting-db-${substr(sha1(local.targeting_init_sql), 0, 8)}"
    namespace = kubernetes_namespace.services["targeting-service"].metadata[0].name
  }

  spec {
    backoff_limit = 2

    template {
      metadata {
        labels = { job = "seed-targeting-db" }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["sh", "-c", "psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f /sql/init.sql"]

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.targeting_service.metadata[0].name
                key  = "DATABASE_URL"
              }
            }
          }

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
          }
        }

        volume {
          name = "sql"
          config_map {
            name = kubernetes_config_map.targeting_init_sql.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}
