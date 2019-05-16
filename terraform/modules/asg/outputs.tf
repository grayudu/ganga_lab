output "this_asg_id" {
  description = "The name of the ASG"
  value       = "${element(concat(aws_autoscaling_group.this.*.id, list("")), 0)}"
}

# output "this_asg_arn" {
#   description = "The ARN of the ASG"
#   value       = "${element(concat(aws_autoscaling_group.this.*.arn, list("")), 0)}"
# }
