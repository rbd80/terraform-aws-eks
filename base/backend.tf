provider "aws" {
  region = "us-east-1"
  profile = "terraform_svc"
}
terraform {
  required_version =">=0.11.3"
  backend "s3" {
    region = "us-east-1"
    bucket = "skeleton-zero-basic-state"
    key = "terraform.tfstate"
    dynamodb_table = "skeleton-zero-basic-state-lock"
    encrypt = true
  }
}
