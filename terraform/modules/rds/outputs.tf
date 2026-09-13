output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.this.name
}
