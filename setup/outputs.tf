output "tf_state_s3" {
  description = "The ARN of the s3 bucket"
  value       = "${module.terraform_state_backend.s3_bucket_id}"
}
output "tf_state_dynamnodb" {
  description = "The ARN of the dynamnodb"
  value       = "${module.terraform_state_backend.dynamodb_table_id}"
}
output "region" {
  description = "AWS Region"
  value       = "${var.region}"
}
output "profile" {
  description = "AWS Profile"
  value       = "${var.profile}"
}