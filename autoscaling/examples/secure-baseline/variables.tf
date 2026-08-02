variable "aws_region" {
  description = "AWS region in which to deploy the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the example Auto Scaling group."
  type        = string
  default     = "secure-application"
}

variable "ami_id" {
  description = "AMI ID used by the launch template."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID from the VPC module."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to reach the application port."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the VPC module."
  type        = list(string)
}

variable "application_port" {
  description = "Application listener port."
  type        = number
  default     = 8080
}

variable "iam_instance_profile_name" {
  description = "Optional IAM instance profile, typically granting Systems Manager access."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional bootstrap user data."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}
