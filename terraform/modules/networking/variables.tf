variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name, used for the kubernetes.io/cluster/<name> subnet tag required by the AWS load balancer / VPC CNI controllers."
  type        = string
}
