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

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = false

  tags = {
    Name = "vpc-ganga"
  }
}

data "aws_caller_identity" "current" {}

data "aws_subnet_ids" "private" {
  vpc_id = "${data.aws_vpc.default.id}"

  #vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name = "ganga-vpc-private-*"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${data.aws_vpc.default.id}"

  #vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Name = "ganga-vpc-public-*"
  }
}

data "aws_subnet" "private-sub" {
  count = "${length(data.aws_subnet_ids.private.ids)}"
  id    = "${data.aws_subnet_ids.private.ids[count.index]}"
}

data "aws_subnet" "public-sub" {
  count = "${length(data.aws_subnet_ids.public.ids)}"
  id    = "${data.aws_subnet_ids.public.ids[count.index]}"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

module "sg" {
  source = "../modules/sg"

  name          = "${var.name}"
  desc          = "${var.desc}"
  aws_vpc_id    = "${data.aws_vpc.default.id}"
  cidr_22       = ["${data.aws_subnet.public-sub.*.cidr_block}"]
  cidr_443      = ["0.0.0.0/0"]
  cidr_ec2_443  = ["${data.aws_subnet.public-sub.*.cidr_block}"]
  cidr_ec2_8080 = ["${data.aws_subnet.private-sub.*.cidr_block}"]
}

module "iam" {
  source = "../modules/iam"

  name = "${var.name}"
}

######
# Launch configuration and autoscaling group
######
module "ganga" {
  source = "../modules/asg"

  name = "ganga-with-ec2"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "ganga-lc"

  image_id                     = "${data.aws_ami.amazon_linux.id}"
  instance_type                = "t2.micro"
  iam_instance_profile         = "${module.iam.this_iam_instance_profile_id}"
  security_groups              = ["${module.sg.this_ec2_sg_id}"]
  load_balancers               = ["${module.ganga-elb.this_elb_id}"]
  associate_public_ip_address  = true
  recreate_asg_when_lc_changes = true
  key_name                     = "${var.key_name}"

  user_data = <<-EOF
              #!/bin/bash
              curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 14.4.56
              mkdir /var/chef
              cd /var/chef
              aws s3 cp s3://${var.app}-${data.aws_caller_identity.current.account_id}-${var.region}/chef-0.1.0.zip .
              unzip chef-0.1.0.zip
              sleep 10
              chef-solo -c /var/chef/solo.rb -o "role[${var.app}_demo_dev]"
              sleep 5
              python /etc/app/app.py
              EOF

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "8"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size           = "10"
      volume_type           = "gp2"
      delete_on_termination = true
    },
  ]

  # Auto scaling group
  asg_name                  = "ganga-asg"
  vpc_zone_identifier       = ["${data.aws_subnet_ids.private.ids}"]
  health_check_type         = "EC2"
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  desired_capacity          = "${var.desired_capacity}"
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.app}"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}

module "ganga-elb" {
  source          = "../modules/elb"
  name            = "ganga-elb"
  security_groups = ["${module.sg.this_lb_sg_id}"]
  subnets         = ["${data.aws_subnet_ids.public.ids}"]
  internal        = "false"

  listener = "${var.listener}"

  health_check = "${var.health_check}"
}

#data "aws_kms_key" "foo" {
#  key_id = "alias/${var.app}"
#}

data "aws_kms_secrets" "ganga-alb-cert" {
  "secret" {
    name    = "alb_cert"
    payload = "${file("/tmp/server.crt")}"
  }
}

data "aws_kms_secrets" "ganga-alb-key" {
  "secret" {
    name    = "alb_key"
    payload = "${file("/tmp/server.key")}"
  }
}

resource "aws_iam_server_certificate" "ganga-cert" {
  name             = "ganga-cert"
  certificate_body = "${data.aws_kms_secrets.ganga-alb-cert.plaintext["alb_cert"]}"
  private_key      = "${data.aws_kms_secrets.ganga-alb-key.plaintext["alb_key"]}"
}

resource "aws_alb" "alb_front" {
  name            = "ganga-alb"
  internal        = false
  security_groups = ["${module.sg.this_lb_sg_id}"]
  subnets         = ["${data.aws_subnet_ids.public.ids}"]

  tags = [
    {
      key                 = "Environment"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.app}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_alb_target_group" "alb_front_https" {
  name     = "alb-front-https"
  vpc_id   = "${data.aws_vpc.default.id}"
  port     = "443"
  protocol = "HTTPS"

  health_check {
    path                = "/health"
    port                = "443"
    protocol            = "HTTPS"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 4
    matcher             = "200-308"
  }

  tags = [
    {
      key                 = "Environment"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.app}"
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${module.ganga.this_asg_id}"
  alb_target_group_arn   = "${aws_alb_target_group.alb_front_https.arn}"
}

resource "aws_alb_listener" "alb_front_https" {
  load_balancer_arn = "${aws_alb.alb_front.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_iam_server_certificate.ganga-cert.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_front_https.arn}"
    type             = "forward"
  }
}

# resource "aws_autoscaling_attachment" "asg_attachment_bar" {
#   autoscaling_group_name = "${module.ganga}"
#   elb                    = "${module.ganga-elb}"
# }

#apply WAF Rules

resource "aws_wafregional_ipset" "ipset" {
  name = "ganga_ipset"

  ip_set_descriptor {
    type  = "IPV4"
    value = "70.209.220.187/32"
  }
}

resource "aws_wafregional_rule" "waf_rule" {
  name        = "gangarule"
  metric_name = "gangarule"

  predicate {
    data_id = "${aws_wafregional_ipset.ipset.id}"
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_wafregional_web_acl" "ipblock" {
  name        = "ipblock"
  metric_name = "ipblock"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = "${aws_wafregional_rule.waf_rule.id}"
  }
}

resource "aws_wafregional_web_acl_association" "rule_assign" {
  resource_arn = "${aws_alb.alb_front.arn}"
  web_acl_id   = "${aws_wafregional_web_acl.ipblock.id}"
}

#ASGMonitor
resource "null_resource" "lambdazip" {
  provisioner "local-exec" {
    command = <<EOT
     cd ../../scripts;zip -r /tmp/asgscale.zip asgscale.py;
   EOT
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_iam"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "asgloadmonitor" {
  filename         = "asgscale.zip"
  function_name    = "asgloadmonitor"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "asgscale.lambda_handler"
  source_code_hash = "${base64sha256(file("asgscale.zip"))}"
  runtime          = "python3.6"

  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.asgscale"]
}

resource "aws_cloudwatch_log_group" "asgscale" {
  name              = "/aws/lambda/asgloadmonitor"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}


resource "aws_sns_topic" "scaleup" {
  name = "asg_scaleup"
}

resource "aws_sns_topic" "scaledown" {
  name = "asg_scaledown"
}

resource "aws_sns_topic_subscription" "scaleup" {
  topic_arn = "${aws_sns_topic.scaleup.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.asgloadmonitor.arn}"
}

resource "aws_sns_topic_subscription" "scaledown" {
  topic_arn = "${aws_sns_topic.scaledown.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.asgloadmonitor.arn}"
}


resource "aws_lambda_permission" "with_sns_scaleup" {
  statement_id  = "AllowExecutionFromSNSup"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.asgloadmonitor.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.scaleup.arn}"
}

resource "aws_lambda_permission" "with_sns_scaledown" {
  statement_id  = "AllowExecutionFromSNSdown"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.asgloadmonitor.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.scaledown.arn}"
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_metric_alarm_rpm_high" {
  alarm_name          = "ganga-asgscale-alarm"
  alarm_actions       = ["${aws_sns_topic.scaleup.arn}"]
  ok_actions          = ["${aws_sns_topic.scaledown.arn}"]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  period              = "60"
  threshold           = "40"
  insufficient_data_actions = []

  dimensions {
    TargetGroup  = "${aws_alb_target_group.alb_front_https.arn_suffix}"
  }
}
