provider "aws" {
  region = "${var.region}"
  profile = "grayudu"
}

#resource "aws_kms_key" "ganga" {
#  description             = "KMS key 1"
#  deletion_window_in_days = 10
#}

resource "aws_s3_bucket" "mybucket" {
  bucket = "${var.bucketname}"
  #acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        #kms_master_key_id = "${aws_kms_key.ganga.id}"
        kms_master_key_id = "aa7b7baf-dcdf-4a94-8115-6b9228839b94"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
