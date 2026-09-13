variable "github_repository" {
  description = "GitHub 'org/repo' allowed to assume this role, e.g. pedrohenriqueortizcosta-blip/togglemaster-fase03."
  type        = string
}

variable "role_name" {
  type    = string
  default = "togglemaster-github-actions-ecr"
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the CI role is allowed to push images to."
  type        = list(string)
}
