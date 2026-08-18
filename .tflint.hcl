config {
  module = false
}

plugin "terraform" {
  enabled = true
}

plugin "aws" {
  enabled = true
  version = "latest"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
  enabled = true
  version = "latest"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
