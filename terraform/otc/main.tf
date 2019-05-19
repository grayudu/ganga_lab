provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

#VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "ganga-vpc"

  cidr = "${var.cidr}"

  azs             = "${var.azs}"
  private_subnets = "${var.private_subnets}"
  public_subnets  = "${var.public_subnets}"

  assign_generated_ipv6_cidr_block = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  vpc_tags = {
    Name = "vpc-ganga"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "b" {
  bucket = "${var.app}-${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = {
    App         = "${var.app}"
    Environment = "Dev"
  }
}

resource "aws_kms_key" "a" {}

resource "aws_kms_alias" "a" {
  name          = "alias/${var.app}"
  target_key_id = "${aws_kms_key.a.key_id}"
}

resource "aws_s3_bucket" "secret_bucket" {
  bucket = "${var.app}-secret-${data.aws_caller_identity.current.account_id}-${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        #kms_master_key_id = "${aws_kms_key.ganga.id}"
        kms_master_key_id = "${aws_kms_key.a.key_id}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name = "ganga-rds-subnet-group"

  #subnet_ids = ["${data.aws_subnet_ids.private.ids}"]
  subnet_ids = ["${module.vpc.private_subnets}"]
}

resource "aws_security_group" "rds-sg" {
  name   = "ganga-rds-sg"
  vpc_id = "${module.vpc.vpc_id}"
}

# Ingress Security Port 3306
resource "aws_security_group_rule" "mysql_inbound_access" {
  from_port = 3306
  protocol  = "tcp"

  security_group_id = "${aws_security_group.rds-sg.id}"
  to_port           = 3306
  type              = "ingress"

  #cidr_blocks       = ["${data.aws_subnet.private-sub.*.cidr_block}"]
  cidr_blocks = ["${var.private_subnets}"]
}

resource "null_resource" "enc_dbpasswd" {
  provisioner "local-exec" {
    command = <<EOT
     aws --profile ${var.profile} --region ${var.region} kms encrypt --key-id ${aws_kms_key.a.key_id} --plaintext ${var.db_passwd} --output text --query CiphertextBlob > /tmp/db_passwd;
     aws --profile ${var.profile} --region ${var.region} kms encrypt --key-id ${aws_kms_key.a.key_id} --plaintext fileb://../../scripts/server.crt --output text --query CiphertextBlob > /tmp/server.crt;
     aws --profile ${var.profile} --region ${var.region} kms encrypt --key-id ${aws_kms_key.a.key_id} --plaintext fileb://../../scripts/server.key --output text --query CiphertextBlob > /tmp/server.key
   EOT
  }
}

resource "null_resource" "s3_upload" {
  provisioner "local-exec" {
    command = <<EOT
     aws --profile ${var.profile} --region ${var.region} s3 cp ../../scripts/sf.jpeg s3://${aws_s3_bucket.b.id} ;
     aws --profile ${var.profile} --region ${var.region} s3api put-object-acl --bucket ${aws_s3_bucket.b.id} --key sf.jpeg --acl public-read;
   EOT
  }
}

resource "null_resource" "chef_upload" {
  provisioner "local-exec" {
    command = <<EOT
     cd ../../chef;zip -r /tmp/chef-0.1.0.zip *;
     aws --profile ${var.profile} --region ${var.region} s3 cp /tmp/chef-0.1.0.zip s3://${aws_s3_bucket.b.id};
   EOT
  }
}

resource "null_resource" "s3secret_ssl_upload" {
  provisioner "local-exec" {
    command = <<EOT
     aws --profile ${var.profile} --region ${var.region} kms encrypt --key-id ${aws_kms_key.a.key_id} --plaintext fileb://../../scripts/server.crt --output text --query CiphertextBlob | base64 --decode > /tmp/nginx_server.crt;
     aws --profile ${var.profile} --region ${var.region} s3api put-object --bucket ${aws_s3_bucket.secret_bucket.id} --key nginx_server.crt --acl private --body /tmp/nginx_server.crt --output text --query 'None' | egrep -v '^None$' || true;
     aws --profile ${var.profile} --region ${var.region} kms encrypt --key-id ${aws_kms_key.a.key_id} --plaintext fileb://../../scripts/server.key --output text --query CiphertextBlob | base64 --decode > /tmp/nginx_server.key;
     aws --profile ${var.profile} --region ${var.region} s3api put-object --bucket ${aws_s3_bucket.secret_bucket.id} --key nginx_server.key --acl private --body /tmp/nginx_server.key --output text --query 'None' | egrep -v '^None$' || true;

   EOT
  }
}

data "aws_kms_secrets" "ganga-rds-secret" {
  "secret" {
    name    = "master_password"
    payload = "${file("/tmp/db_passwd")}"
  }
}

resource "aws_db_instance" "ganga_rds_mysql" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "${var.db_instance}"
  name                        = "${var.db_name}"
  username                    = "admin"
  password                    = "${data.aws_kms_secrets.ganga-rds-secret.plaintext["master_password"]}"
  parameter_group_name        = "default.mysql5.7"
  db_subnet_group_name        = "${aws_db_subnet_group.rds-subnet-group.name}"
  vpc_security_group_ids      = ["${aws_security_group.rds-sg.id}"]
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  backup_window               = "22:00-23:00"
  maintenance_window          = "Sat:00:00-Sat:03:00"
  multi_az                    = true
  skip_final_snapshot         = true
}
