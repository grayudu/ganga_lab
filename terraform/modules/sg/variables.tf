variable "name" {
  description = "The name of the security_groups"
}

variable "desc" {
  description = "The name of the security_groups"
}

variable "aws_vpc_id" {
  description = "VPC main id"
}

variable "cidr_blocks" {
  type        = "list"
  description = "ingress cidr_blocks"
}
