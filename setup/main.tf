terraform {
  required_version = ">= 0.11.3"
}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

module "terraform_state_backend" "master_state" {
  source        = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=master"
  namespace     = "${var.namespace}"
  stage         = "${var.stage}"
  name          = "${var.name}"
  attributes    = ["state"]
  region        = "${var.region}"
  force_destroy = true
  enable_server_side_encryption = true
}

