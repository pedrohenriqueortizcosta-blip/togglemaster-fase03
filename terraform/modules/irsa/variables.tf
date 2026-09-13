variable "role_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without the https:// scheme, e.g. oidc.eks.us-east-1.amazonaws.com/id/XXXX"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string
}

variable "service_account_name" {
  type = string
}

variable "policy_json" {
  description = "IAM permissions policy document (JSON) to attach to this role."
  type        = string
}
