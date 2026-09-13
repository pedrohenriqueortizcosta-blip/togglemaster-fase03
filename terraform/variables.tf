variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used for tagging."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project/cluster name prefix, matches Fase02 naming (togglemaster)."
  type        = string
  default     = "togglemaster"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "kubernetes_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_group_min_size" {
  type    = number
  default = 2
}

variable "node_group_max_size" {
  type    = number
  default = 4
}

variable "node_group_desired_size" {
  type    = number
  default = 2
}

variable "microservices" {
  description = "Canonical list of the 5 ToggleMaster microservices (used to fan out ECR repos, RDS instances where relevant, etc.)."
  type        = list(string)
  default     = ["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"]
}

variable "rds_databases" {
  description = "Per-service RDS PostgreSQL configuration, matching Fase02 database/user names."
  type = map(object({
    identifier = string
    db_name    = string
    username   = string
  }))
  default = {
    auth-service = {
      identifier = "togglemaster-auth-db"
      db_name    = "auth_db"
      username   = "auth_db_user"
    }
    flag-service = {
      identifier = "togglemaster-flag-db"
      db_name    = "flag_db"
      username   = "flag_db_user"
    }
    targeting-service = {
      identifier = "togglemaster-target-db"
      db_name    = "target_db"
      username   = "target_db_user"
    }
  }
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "dynamodb_table_name" {
  type    = string
  default = "ToggleMasterAnalytics"
}

variable "sqs_queue_name" {
  description = "Matches the queue name used in Fase02 (named after the producer service)."
  type        = string
  default     = "togglemaster-evaluation-service"
}

variable "github_repository" {
  description = "GitHub 'org/repo' allowed to assume the CI OIDC role for ECR push."
  type        = string
  default     = "pedrohenriqueortizcosta-blip/togglemaster-fase03"
}
