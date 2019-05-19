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


# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = ["${module.vpc.vpc_cidr_block}"]
}

//output "vpc_ipv6_cidr_block" {
//  description = "The IPv6 CIDR block"
//  value       = ["${module.vpc.vpc_ipv6_cidr_block}"]
//}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.vpc.public_subnets}"]
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = ["${module.vpc.nat_public_ips}"]
}

# AZs
output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = ["${module.vpc.azs}"]
}
