locals {
  cluster_name = var.project_name
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  cluster_name       = local.cluster_name
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name            = local.cluster_name
  kubernetes_version      = var.kubernetes_version
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_subnet_ids      = module.networking.private_subnet_ids
  node_instance_types     = var.node_instance_types
  node_group_min_size     = var.node_group_min_size
  node_group_max_size     = var.node_group_max_size
  node_group_desired_size = var.node_group_desired_size
}

# ---------------------------------------------------------------------------
# RDS: one Postgres instance per stateful service (auth, flag, targeting)
# ---------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  for_each = var.rds_databases

  identifier        = each.value.identifier
  db_name           = each.value.db_name
  username          = each.value.username
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  engine_version    = var.rds_engine_version

  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}

# ---------------------------------------------------------------------------
# ElastiCache (Redis) for evaluation-service
# ---------------------------------------------------------------------------
module "elasticache" {
  source = "./modules/elasticache"

  project_name = var.project_name
  node_type    = var.redis_node_type

  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}

# ---------------------------------------------------------------------------
# DynamoDB for analytics-service
# ---------------------------------------------------------------------------
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = var.dynamodb_table_name
}

# ---------------------------------------------------------------------------
# SQS: evaluation-service (producer) -> analytics-service (consumer)
# ---------------------------------------------------------------------------
module "sqs" {
  source = "./modules/sqs"

  queue_name = var.sqs_queue_name
}

# ---------------------------------------------------------------------------
# ECR: one repository per microservice
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repository_names = var.microservices
}

# ---------------------------------------------------------------------------
# IRSA: evaluation-service can send to SQS
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "evaluation_service_sqs" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [module.sqs.queue_arn]
  }
}

module "irsa_evaluation_service" {
  source = "./modules/irsa"

  role_name            = "${var.project_name}-evaluation-service-irsa"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "evaluation-service"
  service_account_name = "evaluation-service"
  policy_json          = data.aws_iam_policy_document.evaluation_service_sqs.json
}

# ---------------------------------------------------------------------------
# IRSA: analytics-service can consume from SQS and write to DynamoDB
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "analytics_service_sqs_dynamodb" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
    ]
    resources = [module.sqs.queue_arn]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
    ]
    resources = [module.dynamodb.table_arn]
  }
}

module "irsa_analytics_service" {
  source = "./modules/irsa"

  role_name            = "${var.project_name}-analytics-service-irsa"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "analytics-service"
  service_account_name = "analytics-service"
  policy_json          = data.aws_iam_policy_document.analytics_service_sqs_dynamodb.json
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC role for CI to push to ECR (no long-lived AWS keys)
# ---------------------------------------------------------------------------
module "github_oidc" {
  source = "./modules/github-oidc"

  github_repository   = var.github_repository
  role_name           = "${var.project_name}-github-actions-ecr"
  ecr_repository_arns = values(module.ecr.repository_arns)
}
