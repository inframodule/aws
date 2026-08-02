variable "aws_region" {
  description = "AWS region in which to deploy the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the internet-facing Application Load Balancer."
  type        = string
  default     = "public-app"
}

variable "vpc_id" {
  description = "VPC ID from the VPC module."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs from the VPC module."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS."
  type        = string
}

variable "allowed_ipv4_cidrs" {
  description = "IPv4 CIDRs permitted to connect to the public ALB."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "target_security_group_id" {
  description = "Security group associated with target instances."
  type        = string
}

variable "target_instance_ids" {
  description = "EC2 instance IDs to register as targets."
  type        = set(string)
  default     = []
}

variable "target_port" {
  description = "Application port on target instances."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Application health-check path."
  type        = string
  default     = "/health/ready"
}

variable "web_acl_arn" {
  description = "Optional WAFv2 web ACL ARN."
  type        = string
  default     = null
}

variable "access_log_bucket" {
  description = "Optional existing S3 bucket for ALB access logs."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
