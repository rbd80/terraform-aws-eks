data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# Make pretty Label for Cluster
# ---------------------------------------------------------------------------------------------------------------------
module "cluster_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  ##  attributes = ["public"]
  #  delimiter  = "-"
  tags       = "${map("Kubernetes", "Managed EKS","kubernetes.io/cluster/${module.cluster_label.id}","owned")}"
}

#semantic version