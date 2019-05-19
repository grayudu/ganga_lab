#Region
variable "region" {
  type        = "string"
  description = "describe your variable"
  default     = "us-east-1"
}

variable "profile" {
  type        = "string"
  description = "describe your variable"
  default     = "grayudu"
}

variable "cidr" {
  type        = "string"
  description = "describe your variable"
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = "list"
  description = "ingress cidr_blocks"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  type        = "list"
  description = "ingress cidr_blocks"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  type        = "list"
  description = "ingress cidr_blocks"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "app" {
  type        = "string"
  description = "describe your variable"
  default     = "gangaapp"
}

variable "db_name" {
  type        = "string"
  description = "describe your variable"
  default     = "gangardsmysql"
}

#do not set db password here! just variable to for RDS creation
variable "db_passwd" {
  type        = "string"
  description = "Enter db password ******"
}

variable "db_instance" {
  default = "db.t2.micro"
}
