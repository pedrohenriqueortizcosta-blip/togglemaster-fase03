# ---------------------------------------------------------------------------
# Namespaces (one per microservice, matching Fase02's convention)
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "services" {
  for_each = toset(var.microservices)

  metadata {
    name = each.value
  }
}

# ---------------------------------------------------------------------------
# Generated application secrets (never touch git; only live in Terraform
# state, AWS Secrets Manager, and the in-cluster Kubernetes Secret objects
# below — this is the direct fix for Fase02's plaintext-credentials problem)
# ---------------------------------------------------------------------------
resource "random_password" "auth_master_key" {
  length  = 32
  special = false
}

resource "random_password" "evaluation_service_api_key" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "auth_master_key" {
  name                    = "${var.project_name}-auth-master-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "auth_master_key" {
  secret_id     = aws_secretsmanager_secret.auth_master_key.id
  secret_string = random_password.auth_master_key.result
}

resource "aws_secretsmanager_secret" "evaluation_service_api_key" {
  name                    = "${var.project_name}-evaluation-service-api-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "evaluation_service_api_key" {
  secret_id     = aws_secretsmanager_secret.evaluation_service_api_key.id
  secret_string = random_password.evaluation_service_api_key.result
}

# ---------------------------------------------------------------------------
# Read the RDS credentials back out of Secrets Manager to populate k8s Secrets
# ---------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "rds" {
  for_each  = module.rds
  secret_id = each.value.secret_arn
}

locals {
  rds_creds = { for k, v in data.aws_secretsmanager_secret_version.rds : k => jsondecode(v.secret_string) }
}

# ---------------------------------------------------------------------------
# Per-service Kubernetes Secrets
# ---------------------------------------------------------------------------
resource "kubernetes_secret" "auth_service" {
  metadata {
    name      = "auth-service-secret"
    namespace = kubernetes_namespace.services["auth-service"].metadata[0].name
  }

  data = {
    DATABASE_URL = local.rds_creds["auth-service"].database_url
    MASTER_KEY   = random_password.auth_master_key.result
  }
}

resource "kubernetes_secret" "flag_service" {
  metadata {
    name      = "flag-service-secret"
    namespace = kubernetes_namespace.services["flag-service"].metadata[0].name
  }

  data = {
    DATABASE_URL = local.rds_creds["flag-service"].database_url
  }
}

resource "kubernetes_secret" "targeting_service" {
  metadata {
    name      = "targeting-service-secret"
    namespace = kubernetes_namespace.services["targeting-service"].metadata[0].name
  }

  data = {
    DATABASE_URL = local.rds_creds["targeting-service"].database_url
  }
}

resource "kubernetes_secret" "evaluation_service" {
  metadata {
    name      = "evaluation-service-secret"
    namespace = kubernetes_namespace.services["evaluation-service"].metadata[0].name
  }

  data = {
    SERVICE_API_KEY = random_password.evaluation_service_api_key.result
  }
}

# ---------------------------------------------------------------------------
# Non-sensitive config that's only known after apply (the Redis endpoint
# host is AWS-generated, not predictable ahead of time). Everything else
# (in-cluster service DNS names, ports, the SQS/DynamoDB names) is static
# and lives directly in the gitops-managed manifests instead.
# ---------------------------------------------------------------------------
resource "kubernetes_config_map" "evaluation_service" {
  metadata {
    name      = "evaluation-service-config"
    namespace = kubernetes_namespace.services["evaluation-service"].metadata[0].name
  }

  data = {
    REDIS_URL = "redis://${module.elasticache.primary_endpoint_address}:${module.elasticache.port}"
  }
}

# ---------------------------------------------------------------------------
# IRSA-annotated ServiceAccounts: pods using these get temporary AWS
# credentials scoped to exactly the SQS/DynamoDB permissions each service
# needs (module.irsa_*), with no static AWS keys anywhere.
# ---------------------------------------------------------------------------
resource "kubernetes_service_account" "evaluation_service" {
  metadata {
    name      = "evaluation-service"
    namespace = kubernetes_namespace.services["evaluation-service"].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa_evaluation_service.role_arn
    }
  }
}

resource "kubernetes_service_account" "analytics_service" {
  metadata {
    name      = "analytics-service"
    namespace = kubernetes_namespace.services["analytics-service"].metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa_analytics_service.role_arn
    }
  }
}
