terraform {
  backend "s3" {
    bucket       = "togglemaster-tfstate-108101918154"
    key          = "togglemaster/fase03/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
