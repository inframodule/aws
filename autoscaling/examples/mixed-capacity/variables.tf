variable "aws_region" {
  description = "AWS region in which to deploy the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the mixed-capacity Auto Scaling group."
  type        = string
  default     = "mixed-application"
}

variable "ami_id" {
  description = "x86_64 AMI ID compatible with every instance override."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the VPC module."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the VPC module."
  type        = list(string)
}

variable "source_security_group_ids" {
  description = "Security groups allowed to connect to application instances."
  type        = set(string)
}

variable "application_port" {
  description = "Application listener port."
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
