#
# Outputs
#

output "cluster_label" {
  value       = "${module.cluster_label.name}"
}
output "vpc_id" {
  value       = "${module.vpc.vpc_id}"
}
output "Namespace" {
  value       = "${module.cluster_label.namespace}"
}
output "Stage" {
  value       = "${module.cluster_label.stage}"
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "caller_arn" {
  value = "${data.aws_caller_identity.current.arn}"
}

output "caller_user" {
  value = "${data.aws_caller_identity.current.user_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Connection configure for AWS EKS and Config Map
# ---------------------------------------------------------------------------------------------------------------------
locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapAccounts: |
    - "${data.aws_caller_identity.current.account_id}"
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.build.endpoint}
    certificate-authority-data: ${aws_eks_cluster.build.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: heptio-authenticator-aws
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.build.id}"
KUBECONFIG
}
output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}