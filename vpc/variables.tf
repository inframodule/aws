variable "name" {
  description = "Name used for the VPC and its resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0 && length(var.name) <= 64
    error_message = "name must contain between 1 and 64 characters."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Ordered availability zones in which to create subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) > 0 &&
      length(var.availability_zones) == length(distinct(var.availability_zones)) &&
      alltrue([for zone in var.availability_zones : length(trimspace(zone)) > 0])
    )
    error_message = "availability_zones must contain at least one unique, non-empty availability zone."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet IPv4 CIDRs, ordered to match availability_zones. Use an empty list to omit this tier."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every public_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet IPv4 CIDRs, ordered to match availability_zones. Use an empty list to omit this tier."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every private_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "isolated_subnet_cidrs" {
  description = "Isolated subnet IPv4 CIDRs, ordered to match availability_zones. Use an empty list to omit this tier."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.isolated_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every isolated_subnet_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "create_internet_gateway" {
  description = "Whether to attach an internet gateway and route public subnets to it."
  type        = bool
  default     = false
}

variable "nat_gateway_mode" {
  description = "NAT gateway topology for private subnet egress: none, single, or per_az."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, per_az."
  }
}

variable "public_subnet_map_public_ip_on_launch" {
  description = "Whether instances launched in public subnets receive public IPv4 addresses by default."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to publish VPC Flow Logs to a module-managed CloudWatch log group."
  type        = bool
  default     = true
}

variable "flow_log_traffic_type" {
  description = "Traffic captured by VPC Flow Logs."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_log_retention_in_days" {
  description = "CloudWatch retention period for VPC Flow Logs."
  type        = number
  default     = 365

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731,
      1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.flow_log_retention_in_days)
    error_message = "flow_log_retention_in_days must be a CloudWatch Logs supported retention period."
  }
}

variable "flow_log_kms_key_id" {
  description = "Optional KMS key ARN used to encrypt the VPC Flow Logs log group."
  type        = string
  default     = null

  validation {
    condition     = var.flow_log_kms_key_id == null || length(trimspace(var.flow_log_kms_key_id)) > 0
    error_message = "flow_log_kms_key_id must be null or a non-empty KMS key ARN."
  }
}

variable "gateway_endpoints" {
  description = "Gateway VPC endpoints to create. Supported values are s3 and dynamodb."
  type        = set(string)
  default     = ["s3"]

  validation {
    condition     = alltrue([for service in var.gateway_endpoints : contains(["s3", "dynamodb"], service)])
    error_message = "gateway_endpoints supports only s3 and dynamodb."
  }
}

variable "gateway_endpoint_policies" {
  description = "Optional JSON policies keyed by gateway endpoint service name. Omitted services use the AWS default policy."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for service in keys(var.gateway_endpoint_policies) : contains(["s3", "dynamodb"], service)])
    error_message = "gateway_endpoint_policies supports only s3 and dynamodb keys."
  }
}

variable "enable_network_address_usage_metrics" {
  description = "Whether to enable VPC network address usage metrics."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to module resources."
  type        = map(string)
  default     = {}
}
