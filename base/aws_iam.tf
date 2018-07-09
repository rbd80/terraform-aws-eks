# ---------------------------------------------------------------------------------------------------------------------
# Create ALB policy and allow the work nodes to assume it
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "alb-policy" {
  name = "${module.cluster_label.id}-alb-policy"
  role = "${aws_iam_role.alb-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["acm:DescribeCertificate", "acm:ListCertificates"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:ModifyInstanceAttribute",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:GetServerCertificate", "iam:ListServerCertificates"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["waf-regional:GetWebACLForResource"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["tag:GetResources"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf:GetWebACL",
        "waf:AssociateWebACL",
        "waf:DisassociateWebACL"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# Trust Relationship for Worker Node
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "alb-role" {
  name = "${module.cluster_label.id}-alb-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.eks-node.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
data "aws_iam_policy_document" "assume_alb-role" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["${aws_iam_role.alb-role.arn}"]
  }
}

resource "aws_iam_policy" "assume_role_alb" {
  name        = "${module.cluster_label.id}-permit-assume-alb-role"
  description = "Allow assuming alb role"
  policy      = "${data.aws_iam_policy_document.assume_alb-role.json}"
}

resource "aws_iam_role_policy_attachment" "eks_alb" {
  role       = "${aws_iam_role.eks-node.name}"
  policy_arn = "${aws_iam_policy.assume_role_alb.arn}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create Logs policy and allow the work nodes to assume it
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "logs-policy" {
  name = "${module.cluster_label.id}-logs-policy"
  role = "${aws_iam_role.log-role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogsStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups"
            ],
            "Resource": [
            "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "log-role" {
  name = "${module.cluster_label.id}-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                    "AWS": "${aws_iam_role.eks-node.arn}"
                  }
      }
  ]
}
EOF
}

data "aws_iam_policy_document" "assume_logs_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    #resources = ["${aws_iam_role.log-role.arn}"]
    resources = ["${aws_iam_role.eks-node.arn}"]
  }
}

resource "aws_iam_policy" "assume_role_log" {
  name        = "${module.cluster_label.id}-permit-assume-logs-role"
  description = "Allow assuming log role"
  policy      = "${data.aws_iam_policy_document.assume_logs_role.json}"
}

resource "aws_iam_role_policy_attachment" "eks_log" {
  #role       = "${aws_iam_role.eks-node.name}"
  role       = "${aws_iam_role.log-role.name}"
  policy_arn = "${aws_iam_policy.assume_role_log.arn}"
}
