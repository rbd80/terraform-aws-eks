# Terraform: Amazon EKS

This solution uses terraform to built a secure remote state store and then build EKS
and configure a launch configuration for the work nodes
## Assumptions

* [Terraform](https://www.terraform.io/) installed (approach tested against `v0.11.2`)
* [AWS S3 backend](https://www.terraform.io/docs/backends/types/s3.html) with DynamoDB table for locking will be used
* operator should have [AWS credentials in profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html) - for the purpose of this repo we use `terraform` profile
* backend will be created and maintained under `base` workspace
* the terraform_svc account is created

## Development

Before applying you should update `backend.tfvars` with backend configuration. You should also update list of `operators` AWS usernames in the `setup/variables.tf` file.

If you want to use workspaces per environment (as we and [Hashicorp recommends](https://www.terraform.io/docs/enterprise/guides/recommended-practices/part1.html#one-workspace-per-environment-per-terraform-configuration)) it might be convenient to name basic one `base` or leave `default` for backend infrastructure only.

## Explanation

When you run `setup.sh` option 1 the script will create required S3 bucket and DynamoDB table with local backend and then it will
initialize remote backend where it will migrate the local state. Terraform will ask for confirmation during creation of required resources and if operator wants to migrate the state.

Not Option 2 is not fixed so
```bash
    tf_workspace_config base
    AWS_PROFILE=terraform_svc terraform init base
    AWS_PROFILE=terraform_svc terraform plan -var-file=backend.tfvars -input=false -out tf.plan base
    AWS_PROFILE=terraform_svc terraform apply tf.plan
```



## Problems not solved

* AWS S3 policies doesn't support groups so each operator must be added explicit to the policy file
* `-backend=false` doesn't work, so "hack" with separated `setup` directory must be used to run Terraform without S3 backend

## Questions and/or suggestions

Please open an issue if something is not clear or you can suggest a better solution.
