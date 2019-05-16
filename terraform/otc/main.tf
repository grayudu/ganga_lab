provider "aws" {
  region  = "${var.region}"
  profile = "grayudu"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "ganga" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_subnet" "ganga" {
  count = "${length(data.aws_subnet_ids.ganga.ids)}"
  id    = "${data.aws_subnet_ids.ganga.ids[count.index]}"
}

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
  name       = "ganga-rds-subnet-group"
  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
}

resource "aws_security_group" "rds-sg" {
  name   = "ganga-rds-sg"
  vpc_id = "${data.aws_vpc.default.id}"
}

# Ingress Security Port 3306
resource "aws_security_group_rule" "mysql_inbound_access" {
  from_port         = 3306
  protocol          = "tcp"


  security_group_id = "${aws_security_group.rds-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["${data.aws_subnet.ganga.*.cidr_block}"]
}

data "aws_kms_secrets" "ganga-rds-secret" {
  "secret" {
    name    = "master_password"
    payload = "AQICAHhTzl84cWwlwGqOzU72WSmkEJZmMD/anfZ1wb7vIawzAwGD2iNUP/F41dyM99kZz/8iAAAAZjBkBgkqhkiG9w0BBwagVzBVAgEAMFAGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMtJHgtkRh5C8d1ow5AgEQgCOIEs8A31NTcPs4RABt3U/bZa1bvgh6x4PQk+UgSMjyERNpFQ=="
  }
}

resource "aws_db_instance" "ganga_rds_mysql" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "${var.db_instance}"
  name                        = "gangardsmysql"
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


