#Region
variable "region" {
  type        = "string"
  description = "describe your variable"
  default     = "us-west-2"
}
variable "profile" {
  type        = "string"
  description = "describe your variable"
  default     = "grayudu"
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
  description = "Enter DB password ******"
}

variable "db_instance" {
  default = "db.t2.micro"
}
