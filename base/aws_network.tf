# ---------------------------------------------------------------------------------------------------------------------
# Create VPC for cluster
# ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source    = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  namespace = "${module.cluster_label.namespace}"
  stage     = "${module.cluster_label.stage}"
  name      = "${module.cluster_label.name}"
  #tags      = "${module.cluster_label.tags}"
  tags = "${
    map(
     "Name", "${aws_iam_role.eks-node.name}",
     "kubernetes.io/cluster/${module.cluster_label.id}", "owned",
    )
  }"
}
# ---------------------------------------------------------------------------------------------------------------------
# Create dynamic subnets for cluster
# ---------------------------------------------------------------------------------------------------------------------
module "dynamic_subnets" {
  source             = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace          = "${module.cluster_label.namespace}"
  stage              = "${module.cluster_label.stage}"
  name               = "${module.cluster_label.name}"
  region             = "${var.region}"
  availability_zones = ["${var.region}a","${var.region}b","${var.region}d"]
  vpc_id             = "${module.vpc.vpc_id}"
  igw_id             = "${module.vpc.igw_id}"
  cidr_block         = "${var.cidr_block}"
  #tags      = "${module.cluster_label.tags}"
  tags = "${
    map(
     "Name", "${aws_iam_role.eks-node.name}",
     "kubernetes.io/cluster/${module.cluster_label.id}", "owned",
    )
  }"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create dynamic subnets for cluster
# ---------------------------------------------------------------------------------------------------------------------
data "aws_subnet_ids" "public" {
  vpc_id = "${module.vpc.vpc_id}"
}

