variable "app" {
  type        = "string"
  description = "describe your variable"
  default     = "ganga"
}

variable "profile" {
  type        = "string"
  description = "describe your variable"
  default     = "grayudu"
}

variable "bucketname" {
  type        = "string"
  description = "describe your variable"
  default     = "gangaapp-101189138796-us-west-2"
}
#terraform lock
variable "bucket" {
  type        = "string"
  description = "describe your variable"
  default     = "terraform-statelock-store-useast"
}
variable "dynamodb_table" {
  type        = "string"
  description = "describe your variable"
  default     = "terraform-statelock-useast"
}
#Region
variable "region" {
  type        = "string"
  description = "describe your variable"
  default     = "us-west-2"
}
#Security Group
variable "name" {
  type        = "string"
  description = "describe your variable"
  default     = "ganga-sg"
}

variable "desc" {
  type        = "string"
  description = "describe your variable"
  default     = "app1 security group"
}

#ASG Variables
variable "key_name" {
  type        = "string"
  description = "describe your key_name variable"
  default     = "ganga_uswest2"
}

variable "min_size" {
  description = "describe your min_size variable"
  default     = 1
}

variable "max_size" {
  description = "describe your  max_size variable"
  default     = 1
}

variable "desired_capacity" {
  description = "describe your desired_capacity variable"
  default     = 1
}

variable "env" {
  description = "describe your env variable"
  default     = "dev"
}

variable "appName" {
  description = "describe your appName variable"
  default     = "gangademo"
}

# variable "from_port" {
#   description = "from_port"
#   default     = 80
# }

# variable "to_port" {
#   description = "describe from_port"
#   default     = 80
# }

# variable "protocol" {
#   description = "describe protocol"
#   default     = "tcp"
# }

# variable "cidr_blocks" {
#   description = "describe cidr_blocks"
#   default     = ["0.0.0.0/0"]
# }

# ELB
variable "listener" {
  description = "ELB litener details"

  default = [{
    instance_port = 80

    instance_protocol = "http"

    lb_port = 80

    lb_protocol = "http"
  },
    {
      instance_port = 443

      instance_protocol = "tcp"

      lb_port = 443

      lb_protocol = "tcp"
    },
  ]
}

variable "health_check" {
  description = "health_check details for ELB"

  default = [
    {
      target              = "TCP:80"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}
