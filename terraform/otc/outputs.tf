output "repo_s3bucket" {
  description = "The repo_s3bucket"
  value       = "${aws_s3_bucket.b.id}"
}

output "secret_s3bucket" {
  description = "The secret_s3bucket"
  value       = "${aws_s3_bucket.secret_bucket.id}"
}

output "aws_kms" {
  description = "The KMS ID"
  value       = "${aws_kms_key.a.id}"
}

output "aws_rds" {
  description = "The RDS ID"
  value       = "${aws_db_instance.ganga_rds_mysql.endpoint}"
}

output "aws_rds_name" {
  description = "The RDS db name"
  value       = "${aws_db_instance.ganga_rds_mysql.name}"
}
