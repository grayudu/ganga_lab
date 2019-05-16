output "this_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.ganga-elb.this_elb_dns_name}"
}

output "alb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${aws_alb.alb_front.dns_name}"
}
