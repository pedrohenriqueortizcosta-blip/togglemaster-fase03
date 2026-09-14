variable "project_name" {
  type = string
}

variable "node_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to reach Redis on 6379 (the EKS cluster security group)."
  type        = string
}
