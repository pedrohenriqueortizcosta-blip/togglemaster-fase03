variable "identifier" {
  description = "RDS instance identifier, e.g. togglemaster-auth-db."
  type        = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "engine_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to reach Postgres on 5432 (the EKS cluster security group)."
  type        = string
}
