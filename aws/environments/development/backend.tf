terraform {
  backend "s3" {
    bucket       = "x-devops-tf-state" # Output from aws/bootstrap
    key          = "development/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
