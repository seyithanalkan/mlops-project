terraform {
  backend "s3" {
    bucket       = "seyithan-mlops-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
