variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for EC2 Name tags."
  type        = string
  default     = "compute"
}

variable "instance_count" {
  description = "Number of instances to deploy."
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID to use for instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID for instance placement and security group creation."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for instance placement."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH/RDP."
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IPs."
  type        = bool
  default     = false
}

variable "allow_public_ip" {
  description = "Guardrail to allow public IP assignment."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "imds_http_tokens" {
  description = "IMDSv2 token requirement."
  type        = string
  default     = "required"
}

variable "imds_http_endpoint" {
  description = "Whether the IMDS endpoint is enabled."
  type        = string
  default     = "enabled"
}

variable "imds_http_put_response_hop_limit" {
  description = "IMDS response hop limit."
  type        = number
  default     = 1
}

variable "imds_instance_metadata_tags" {
  description = "Whether instance tags are available via the metadata service."
  type        = string
  default     = "disabled"
}

variable "imds_http_protocol_ipv6" {
  description = "Whether the metadata service supports IPv6."
  type        = string
  default     = "disabled"
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

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH. Defaults to allowed_cidr_blocks when null."
  type        = list(string)
  default     = null
}

variable "rdp_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access RDP. Defaults to allowed_cidr_blocks when null."
  type        = list(string)
  default     = null
}
