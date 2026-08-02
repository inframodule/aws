variable "aws_region" {
  description = "AWS region in which to deploy the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the internal Application Load Balancer."
  type        = string
  default     = "private-app"
}

variable "vpc_id" {
  description = "VPC ID from the VPC module."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from the VPC module."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS."
  type        = string
}

variable "client_security_group_ids" {
  description = "Security groups permitted to connect to the internal ALB."
  type        = set(string)
}

variable "target_security_group_id" {
  description = "Security group associated with the target instances."
  type        = string
}

variable "target_instance_ids" {
  description = "EC2 instance IDs to register as targets."
  type        = set(string)
  default     = []
}

variable "target_port" {
  description = "Application port on the target instances."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Application health-check path."
  type        = string
  default     = "/health/ready"
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
