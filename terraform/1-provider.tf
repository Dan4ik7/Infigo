provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "aws" {
    bucket = "tf-state-infigo"
    prefix = "terraform/state"
  }
  
}