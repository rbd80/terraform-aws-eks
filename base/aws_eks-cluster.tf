#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

# ---------------------------------------------------------------------------------------------------------------------
# EKS IAM role and allow to AssumeRoles for terraform_svc
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "eks" {
  name = "${module.cluster_label.id}"
  force_detach_policies = "true"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com",
        "AWS": "${data.aws_caller_identity.current.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks.name}"
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks.name}"
}

resource "aws_eks_cluster" "build" {
  name            = "${module.cluster_label.id}"
  role_arn        = "${aws_iam_role.eks.arn}"

  vpc_config {
    subnet_ids = ["${module.dynamic_subnets.private_subnet_ids}"]
    security_group_ids = ["${aws_security_group.cluster.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-AmazonEKSServicePolicy",
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Setup the AWS Security Groups
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "Cluster_${module.cluster_label.id}"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${module.cluster_label.tags}"

}
resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.eks-node.id}"
  to_port                  = 443
  type                     = "ingress"
}