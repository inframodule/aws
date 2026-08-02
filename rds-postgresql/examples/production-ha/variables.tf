variable "aws_region" {
  type = string
}

variable "identifier" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "application_security_group_ids" {
  type = set(string)
}

variable "database_kms_key_id" {
  type = string
}

variable "secret_kms_key_id" {
  type = string
}

variable "logs_kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
