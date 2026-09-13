output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this to update your local kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_secret_names" {
  description = "AWS Secrets Manager secret names holding each service's DATABASE_URL."
  value       = { for k, v in module.rds : k => v.secret_name }
}

output "redis_endpoint" {
  value = module.elasticache.primary_endpoint_address
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "github_actions_role_arn" {
  description = "Put this in the repo variable AWS_ROLE_ARN for the CI workflows."
  value       = module.github_oidc.role_arn
}

output "evaluation_service_irsa_role_arn" {
  value = module.irsa_evaluation_service.role_arn
}

output "analytics_service_irsa_role_arn" {
  value = module.irsa_analytics_service.role_arn
}
