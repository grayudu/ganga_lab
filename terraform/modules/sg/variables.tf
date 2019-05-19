variable "name" {
  description = "The name of the security_groups"
}

variable "desc" {
  description = "The name of the security_groups"
}

variable "aws_vpc_id" {
  description = "VPC main id"
}

variable "cidr_22" {
  type        = "list"
  description = "ingress cidr_blocks"
}

variable "cidr_443" {
  type        = "list"
  description = "ingress cidr_blocks"
}

variable "cidr_ec2_443" {
  type        = "list"
  description = "ingress cidr_blocks"
}

variable "cidr_ec2_8080" {
  type        = "list"
  description = "ingress cidr_blocks"
}
