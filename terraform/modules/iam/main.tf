resource "aws_iam_role" "this" {
  name = "${var.name}_instance_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy" {
 name = "s3-policy"
 description = "A s3 policy"
 policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
               "s3:*",
               "autoscaling:Describe*",
               "kms:Encrypt",
               "kms:Decrypt",
               "ec2:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3-attach" {
  name       = "s3-attachment"
  roles      = ["${aws_iam_role.this.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}_instance_profile"
  role = "${aws_iam_role.this.name}"
}
