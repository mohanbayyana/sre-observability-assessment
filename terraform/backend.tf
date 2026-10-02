terraform {
  backend "gcs" {
    bucket = "mohan-sre-assessment-20261001-tfstate"
    prefix = "terraform/state"
  }
}
