variable "bucketname" {
  description = "describe your variable"
  default     = "default value"
}

variable "region" {
  description = "describe your variable"
  default     = "default value"
}

variable "enabled" {
  type        = "string"
  description = "Set to `false` to prevent the module from creating any resources"
  default     = "true"
}
