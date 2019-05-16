#Region
variable "region" {
  type        = "string"
  description = "describe your variable"
  default     = "us-west-2"
}
variable "app" {
  type        = "string"
  description = "describe your variable"
  default     = "gangaapp"
}

variable "db_instance" {
  default = "db.t2.micro"
}
