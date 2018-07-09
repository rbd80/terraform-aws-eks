#!/usr/bin/env bash
#
# this script is used for bootstraping the project base infrastructure
#
# src: https://www.terraform.io/docs/state/workspaces.html
# Setup workspace has the local state store and creates the s3 bucket

function cleanbackend {
# Reset backend.tf
cat <<EOF > base/backend.tf
backend "s3" {
}
EOF
}

function tf_s3_backend {
    #TODO: Check if s3 bucket exists assume we don't need it
    cleanbackend
    cd setup
    # ---------------------------------------------------------------------------------------------------------------------
    # Create the setup
    # You must provide a value for each of these parameters.
    # ---------------------------------------------------------------------------------------------------------------------
    export tf_aws_region=$(AWS_PROFILE=terraform_svc terraform output region)
    export tf_state_s3=$(AWS_PROFILE=terraform_svc terraform output tf_state_s3)
    export tf_aws_profile=$(AWS_PROFILE=terraform_svc terraform output profile)
    export tf_state_dynamnodb=$(AWS_PROFILE=terraform_svc terraform output tf_state_dynamnodb)
if [ -e ../base/backend.tf ]
then
    rm -f ../base/backend.tf
fi
cat <<EOF > ../base/backend.tf
provider "aws" {
  region = "$tf_aws_region"
  profile = "$tf_aws_profile"
}
terraform {
  required_version =">=0.11.3"
  backend "s3" {
    region = "$tf_aws_region"
    bucket = "$tf_state_s3"
    key = "terraform.tfstate"
    dynamodb_table = "$tf_state_dynamnodb"
    encrypt = true
  }
}
EOF
}

function tf_remove() {
    AWS_PROFILE=terraform_svc terraform destroy -var-file=backend.tfvars -auto-approve
    tf_workspace_config default
    tf_workspaceremove base
    cd setup
    AWS_PROFILE=terraform_svc terraform destroy -var-file=../backend.tfvars -lock=false -auto-approve
    ##Remove old state files
    rm -rf terraform.tfstate.d
    rm -rf terraform/
    rm -rf terraform.tfstate
    rm -rf terraform.tfstate.backup
}

function tf_workspaceremove() {
    local readonly name="$1"
    AWS_PROFILE=terraform_svc terraform workspace delete ${name}
}

function tf_build(){
    local readonly name="$1"
    tf_workspace_config ${name}
    #AWS_PROFILE=terraform_svc terraform init ${name}
    AWS_PROFILE=terraform_svc terraform plan -var-file=backend.tfvars -input=false -out tf.plan ${name}
    AWS_PROFILE=terraform_svc terraform apply tf.plan

}

function tfs3_backend(){
    ### DON'T use Workspace for this one
    cd setup
    AWS_PROFILE=terraform_svc terraform init -input=false -backend-config=../backend.tfvars
    AWS_PROFILE=terraform_svc terraform plan -input=false -var-file=../backend.tfvars -out=tfplan
    AWS_PROFILE=terraform_svc terraform apply -input=false tfplan
    cd ..
    tf_s3_backend
}


function tf_workspace_config() {
    local readonly name="$1"
    AWS_PROFILE=terraform_svc terraform workspace select ${name} || AWS_PROFILE=terraform_svc terraform workspace new ${name}
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure the AWS connection
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
function tf_eks_config() {
    #TODO having problems with exporting the config
    #AWS_PROFILE=terraform_svc terraform init base
    echo $(AWS_PROFILE=terraform_svc terraform output config-map-aws-auth base)
    AWS_PROFILE=terraform_svc terraform output config-map-aws-auth >> kubernetes/manifests/awsauth/config-map-aws-auth.yaml
    AWS_PROFILE=terraform_svc kubectl apply -f config-map-aws-auth.yaml
    #AWS_PROFILE=terraform_svc terraform output kubeconfig base >> ~/.kube/$(AWS_PROFILE=terraform_svc terraform output cluster_label base)-config
}

function build_template_cluster() {
    AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/awsauth/config-map-aws-auth.yaml
    AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/rbac/eks-admin-service-account.yaml
    AWS_PROFILE=terraform_svc kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.0.0/config/v1.0/aws-k8s-cni-calico.yaml
    AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/storage/gp2-storage-class.yaml
    AWS_PROFILE=terraform_svc kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    ### https://github.com/kubernetes/helm/blob/master/docs/tiller_ssl.md
    AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/HELM/helm_tiller.yaml
    #AWS_PROFILE=terraform_svc helm init --tiller-tls --tiller-tls-cert ./tiller.cert.pem --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem --service-account=tiller
    #AWS_PROFILE=terraform_svc helm ls --tls --tls-ca-cert ca.cert.pem --tls-cert helm.cert.pem --tls-key helm.key.pem

    AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/kube2iam/kube2iam.yaml

    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/alb-ingress/alb-ingress-controller.yaml
    #https://github.com/app-registry/appr-helm-plugin
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/externaldns/externaldns.yaml


#kubectl delete namespace helm-tiller get deployment
#kubectl -n kube-system get po
#kubectl -n kube-system logs alb-ingress-controller-744cd68896-lmnq5
#AWS_PROFILE=terraform_svc kubectl -n helm-tiller get svc/tiller-deploy deploy/tiller-deploy
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/kube2iam/kube2iam.yaml
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/HELM/helm_tiller.yaml
    #TODO Add the secure option
#AWS_PROFILE=terraform_svc helm repo add stable https://kubernetes-charts.storage.googleapis.com
#AWS_PROFILE=terraform_svc kubectl -n kube-system delete deployment tiller-deploy

   #istio
#AWS_PROFILE=terraform_svc kubectl -n kube-system get deployment
#AWS_PROFILE=terraform_svc kubectl logs tiller-deploy-5dbc7f7dc5-8gp8p -n kube-system

#AWS_PROFILE=terraform_svc kubectl get nodes -n kube-system
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/prometheus-operator
    #AWS_PROFILE=terraform_svc kubectl delete -f kubernetes/manifests/monitoring/prometheus-operator
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/Prometheus/
    #AWS_PROFILE=terraform_svc kubectl delete -f kubernetes/Prometheus/

AWS_PROFILE=terraform_svc helm ls --tls --tls-ca-cert ca.cert.pem --tls-cert helm.cert.pem --tls-key helm.key.pem

    #####********
    #cd scripts; ./generate-alertmanager-config-secret.sh; cd ..
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/prometheus-operator
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/alertmanager
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/node-exporter
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/kube-state-metrics
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/kube-state-metrics

    #AWS_PROFILE=terraform_svc kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com -n

    ########*******
    #### Granfana
    ### TODO setup a IAM Role
    ##  granadmin/MagicSecret
    #AWS_PROFILE=terraform_svc kubectl create secret generic grafana-credentials --from-literal=user=granadmin --from-literal=password=MagicSecret
    #cd ./scripts; ./generate-dashboards-configmap.sh; cd ..
    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring/grafana

    ######

    #AWS_PROFILE=terraform_svc kubectl apply -f kubernetes/manifests/monitoring

}



function istio() {

    cd kubernetes/istio && curl -L https://git.io/getLatestIstio | sh -
    AWS_PROFILE=terraform_svc helm install kubernetes/istio/istio-0.8.0/install/kubernetes/helm/istio --name istio --namespace istio-system
}
#terraform init -backend-config=backend.tfvars setup
#terraform apply -var-file=backend.tfvars setup
# migrate local state to the remote with the s3 bucket and dynamodb table
# terraform init base
# terraform init os
# terraform init setup
# terraform workspace select setup base

#terraform init -backend-config=base/backend.tfvars setup
# terraform workspace delete -force base

#terraform apply -var-file=backend.tfvars base
# terraform init -backend-config=backend.tfvars setup
# terraform apply -var-file=backend.tfvars -lock=false setup
# terraform plan -var-file=backend.tfvars base

# terraform init -backend-config=backend.tfvars -input=false base
#
#
#
#
# terraform destroy -var-file=backend.tfvars -input=false base
# terraform destroy -var-file=backend.tfvars -input=false -lock=false setup

drawMenu() {
	# clear the screen
	tput clear

	# Move cursor to screen location X,Y (top left is 0,0)
	tput cup 3 15

	# Set a foreground colour using ANSI escape
	tput setaf 3
	echo "Setup Clean AWS EKS"
	tput sgr0

	tput cup 5 17
	# Set reverse video mode
	tput rev
	echo "M A I N - M E N U"
	tput sgr0

	tput cup 7 15
	echo "1. Setup the Terraform State (NOT on TF workspace)"

	tput cup 8 15
	echo "2. Build the EKS cluster the worker nodes, Terraform"

	tput cup 9 15
	echo "3. Harden Cluster"

	tput cup 10 15
	echo "4. Delete the AWS Pipeline, Terraform "

	tput cup 12 15
	echo "5. Delete AWS service account for Terraform & Packer"

	# Set bold mode
	tput bold
	tput cup 14 15
	# The default value for PS3 is set to #?.
	# Change it i.e. Set PS3 prompt
	read -p "Enter your choice [1-5] " choice
}

drawMenu
tput sgr0
# set deployservice list
case $choice in
	1)
		echo "#########################"
		echo "Create the Terraform state store LOCAL and Builds S3"
        tfs3_backend
		echo "#########################"
		;;
	2)
		echo "#########################"
		echo "Change State to S3 and Build the AWS network and Security Groups"
        tf_build base
        #tf_eks_config
		echo "#########################"
		;;
	3)
		echo "#########################"
		echo "Setup up Kubernetes."
		#tf_eks_config
		build_template_cluster
		#ssh -i "${NAME}.pem" "admin@api.${NAME}"
		#ssh -i production.solveblock.org.pem.pub admin@ip-172-20-35-10.ec2.internal
		echo "#########################"
		;;
	4)
		echo "#########################"
		echo "Delete the AWS Pipeline, Terraform "
		terraform workspace setup network
		#terraform_delete
		echo "#########################"
		;;
	5)
		echo "#########################"
		echo "Delete the AWS Pipeline, Terraform / Destroy the accounts."
		tf_remove
		echo "#########################"
		;;
	*)
		echo "Error: Please try again (select 1..5)!"
		;;
esac