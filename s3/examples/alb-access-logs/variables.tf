variable "aws_region" {
  description = "AWS region containing both the ALB and log bucket."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the ALB access-log bucket."
  type        = string
}

variable "log_prefix" {
  description = "S3 prefix passed to the ALB access-log configuration. Must not contain AWSLogs."
  type        = string
  default     = "alb/application"

  validation {
    condition     = !strcontains(var.log_prefix, "AWSLogs")
    error_message = "log_prefix must not contain AWSLogs."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain ALB access logs."
  type        = number
  default     = 365
}

variable "alb_name" {
  description = "Name of the Application Load Balancer."
  type        = string
  default     = "public-application"
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
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
}

variable "allowed_ipv4_cidrs" {
  description = "IPv4 CIDRs permitted to connect to the ALB."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "target_security_group_id" {
  description = "Security group associated with the ALB targets."
  type        = string
}

variable "target_port" {
  description = "Application port on the ALB targets."
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
