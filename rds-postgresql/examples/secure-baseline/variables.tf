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

variable "application_security_group_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
