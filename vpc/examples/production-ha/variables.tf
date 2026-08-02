variable "aws_region" {
  description = "AWS region in which to deploy the example."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name used for the example VPC."
  type        = string
  default     = "production-ha"
}

variable "flow_log_kms_key_id" {
  description = "Optional KMS key ARN for Flow Logs encryption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags for example resources."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
