variable "name_prefix" {
  description = "Optional prefix for the Name tag on each instance."
  type        = string
  default     = null
}

variable "instance_count" {
  description = "Number of EC2 instances to create."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "ami_id" {
  description = "AMI ID to use for the instance(s)."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to place instances in (round-robin)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instances."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a security group for the instances."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID used when creating the security group."
  type        = string
  default     = null

  validation {
    condition     = var.create_security_group == false || (var.vpc_id != null && length(var.vpc_id) > 0)
    error_message = "vpc_id must be set when create_security_group is true."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH/RDP."
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_security_group == false || var.enable_ssh == false && var.enable_rdp == false || length(var.allowed_cidr_blocks) > 0
    error_message = "allowed_cidr_blocks must be set when create_security_group is true and SSH/RDP are enabled."
  }
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "Optional IAM instance profile name to attach."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional user data script to pass to instances."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance(s)."
  type        = bool
  default     = false

  validation {
    condition     = var.allow_public_ip || var.associate_public_ip_address == false
    error_message = "associate_public_ip_address must be false unless allow_public_ip is true."
  }
}

variable "allow_public_ip" {
  description = "Guardrail to allow public IP assignment."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "root_block_device" {
  description = "Root block device settings."
  type = object({
    volume_size           = number
    volume_type           = string
    encrypted             = bool
    delete_on_termination = bool
    iops                  = optional(number)
    throughput            = optional(number)
  })
  default = null

  validation {
    condition = var.root_block_device == null || (
      (var.require_volume_encryption == false || var.root_block_device.encrypted == true) &&
      (var.kms_key_id == null || var.root_block_device.encrypted == true)
    )
    error_message = "root_block_device.encrypted must be true when require_volume_encryption is enabled or kms_key_id is set."
  }
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach."
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    encrypted             = bool
    delete_on_termination = bool
    iops                  = optional(number)
    throughput            = optional(number)
  }))
  default = []

  validation {
    condition = (
      (var.require_volume_encryption == false || alltrue([for device in var.ebs_block_device : device.encrypted == true])) &&
      (var.kms_key_id == null || alltrue([for device in var.ebs_block_device : device.encrypted == true]))
    )
    error_message = "All ebs_block_device entries must have encrypted = true when require_volume_encryption is enabled or kms_key_id is set."
  }
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH. Defaults to allowed_cidr_blocks when null."
  type        = list(string)
  default     = null

  validation {
    condition     = var.ssh_allowed_cidr_blocks == null || length(var.ssh_allowed_cidr_blocks) > 0
    error_message = "ssh_allowed_cidr_blocks must be empty or contain at least one CIDR block."
  }
}

variable "rdp_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access RDP. Defaults to allowed_cidr_blocks when null."
  type        = list(string)
  default     = null

  validation {
    condition     = var.rdp_allowed_cidr_blocks == null || length(var.rdp_allowed_cidr_blocks) > 0
    error_message = "rdp_allowed_cidr_blocks must be empty or contain at least one CIDR block."
  }
}

variable "require_volume_encryption" {
  description = "Whether to enforce volume encryption in module inputs."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID/ARN to use for EBS encryption."
  type        = string
  default     = null
}

variable "enable_ssh" {
  description = "Whether to allow SSH ingress in the managed security group."
  type        = bool
  default     = true
}

variable "enable_rdp" {
  description = "Whether to allow RDP ingress in the managed security group."
  type        = bool
  default     = true
}

variable "imds_http_tokens" {
  description = "IMDSv2 token requirement. Use \"required\" to enforce IMDSv2."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "optional"], var.imds_http_tokens)
    error_message = "imds_http_tokens must be \"required\" or \"optional\"."
  }
}

variable "imds_http_endpoint" {
  description = "Whether the IMDS endpoint is enabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_http_endpoint)
    error_message = "imds_http_endpoint must be \"enabled\" or \"disabled\"."
  }
}

variable "imds_http_put_response_hop_limit" {
  description = "IMDS response hop limit."
  type        = number
  default     = 1

  validation {
    condition     = var.imds_http_put_response_hop_limit >= 1 && var.imds_http_put_response_hop_limit <= 64
    error_message = "imds_http_put_response_hop_limit must be between 1 and 64."
  }
}

variable "imds_instance_metadata_tags" {
  description = "Whether instance tags are available via the metadata service."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_instance_metadata_tags)
    error_message = "imds_instance_metadata_tags must be \"enabled\" or \"disabled\"."
  }
}

variable "imds_http_protocol_ipv6" {
  description = "Whether the metadata service supports IPv6."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_http_protocol_ipv6)
    error_message = "imds_http_protocol_ipv6 must be \"enabled\" or \"disabled\"."
  }
}
