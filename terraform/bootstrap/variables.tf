variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket used as the Terraform remote state backend for the main togglemaster/fase03 config."
  type        = string
  default     = "togglemaster-tfstate-108101918154"
}
