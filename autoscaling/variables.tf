variable "name" {
  description = "Name prefix used for the Auto Scaling group and related resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0 && length(var.name) <= 64
    error_message = "name must contain between 1 and 64 characters."
  }
}

variable "ami_id" {
  description = "AMI ID used by the launch template."
  type        = string

  validation {
    condition     = can(regex("^ami-(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{17})$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID."
  }
}

variable "instance_type" {
  description = "Default EC2 instance type used by the launch template."
  type        = string

  validation {
    condition     = length(trimspace(var.instance_type)) > 0
    error_message = "instance_type must be non-empty."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs across which instances are distributed."
  type        = list(string)

  validation {
    condition = (
      length(var.subnet_ids) >= 2 &&
      length(var.subnet_ids) == length(distinct(var.subnet_ids)) &&
      alltrue([for id in var.subnet_ids : length(trimspace(id)) > 0])
    )
    error_message = "subnet_ids must contain at least two unique, non-empty subnet IDs."
  }
}

variable "min_size" {
  description = "Minimum Auto Scaling group capacity."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be zero or greater."
  }
}

variable "desired_capacity" {
  description = "Initial desired capacity. Subsequent changes are managed by Auto Scaling policies and ignored by Terraform."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 0
    error_message = "desired_capacity must be zero or greater."
  }
}

variable "max_size" {
  description = "Maximum Auto Scaling group capacity."
  type        = number
  default     = 4

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least one."
  }
}

variable "create_security_group" {
  description = "Whether to create a managed security group for group instances."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID used by the managed security group."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must be null or non-empty."
  }
}

variable "security_group_ids" {
  description = "Additional or externally managed security group IDs attached to instances."
  type        = set(string)
  default     = []
}

variable "application_port" {
  description = "Application port allowed by managed security-group rules."
  type        = number
  default     = 8080

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "application_port must be between 1 and 65535."
  }
}

variable "ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach the application port on the managed security group."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ingress_ipv4_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every ingress_ipv4_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "ingress_ipv6_cidrs" {
  description = "IPv6 CIDRs allowed to reach the application port on the managed security group."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ingress_ipv6_cidrs : can(cidrhost(cidr, 0)) && can(regex(":", cidr))
    ])
    error_message = "Every ingress_ipv6_cidrs entry must be a valid IPv6 CIDR."
  }
}

variable "ingress_source_security_group_ids" {
  description = "Security group IDs allowed to reach the application port on the managed security group."
  type        = set(string)
  default     = []
}

variable "egress_ipv4_cidrs" {
  description = "IPv4 CIDRs instances may reach through the managed security group."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.egress_ipv4_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every egress_ipv4_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "egress_ipv6_cidrs" {
  description = "IPv6 CIDRs instances may reach through the managed security group."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.egress_ipv6_cidrs : can(cidrhost(cidr, 0)) && can(regex(":", cidr))
    ])
    error_message = "Every egress_ipv6_cidrs entry must be a valid IPv6 CIDR."
  }
}

variable "egress_destination_security_group_ids" {
  description = "Security group IDs instances may reach through the managed security group."
  type        = set(string)
  default     = []
}

variable "egress_from_port" {
  description = "First TCP port allowed by managed security-group egress rules."
  type        = number
  default     = 443

  validation {
    condition     = var.egress_from_port >= 1 && var.egress_from_port <= 65535
    error_message = "egress_from_port must be between 1 and 65535."
  }
}

variable "egress_to_port" {
  description = "Last TCP port allowed by managed security-group egress rules."
  type        = number
  default     = 443

  validation {
    condition     = var.egress_to_port >= 1 && var.egress_to_port <= 65535
    error_message = "egress_to_port must be between 1 and 65535."
  }
}

variable "associate_public_ip_address" {
  description = "Whether instances receive public IPv4 addresses."
  type        = bool
  default     = false
}

variable "allow_public_ip" {
  description = "Guardrail that must be enabled before public IPv4 assignment is allowed."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Optional EC2 key pair name. Prefer AWS Systems Manager Session Manager for administration."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Optional IAM instance profile name attached to instances."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Optional plain-text user data. The module base64-encodes this value for the launch template."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_detailed_monitoring" {
  description = "Whether EC2 detailed monitoring is enabled."
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Whether instances are launched as EBS optimized. Null uses the instance-type default."
  type        = bool
  default     = null
}

variable "root_device_name" {
  description = "Device name for the root EBS volume."
  type        = string
  default     = "/dev/xvda"
}

variable "root_block_device" {
  description = "Root EBS volume configuration."
  type = object({
    volume_size           = optional(number, 20)
    volume_type           = optional(string, "gp3")
    encrypted             = optional(bool, true)
    delete_on_termination = optional(bool, true)
    iops                  = optional(number, 3000)
    throughput            = optional(number, 125)
  })
  default = {}

  validation {
    condition = (
      var.root_block_device.volume_size > 0 &&
      contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], var.root_block_device.volume_type)
    )
    error_message = "root_block_device requires a positive volume_size and a supported EBS volume_type."
  }
}

variable "ebs_block_devices" {
  description = "Additional EBS volumes included in the launch template."
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    encrypted             = optional(bool, true)
    delete_on_termination = optional(bool, true)
    iops                  = optional(number)
    throughput            = optional(number)
  }))
  default = []

  validation {
    condition = (
      length(var.ebs_block_devices) == length(distinct([for device in var.ebs_block_devices : device.device_name])) &&
      alltrue([for device in var.ebs_block_devices : (
        length(trimspace(device.device_name)) > 0 &&
        device.volume_size > 0 &&
        contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], device.volume_type)
      )])
    )
    error_message = "Additional EBS devices require unique non-empty names, positive sizes, and supported volume types."
  }
}

variable "require_volume_encryption" {
  description = "Whether all declared EBS volumes must be encrypted."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN used to encrypt all EBS volumes."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || length(trimspace(var.kms_key_id)) > 0
    error_message = "kms_key_id must be null or non-empty."
  }
}

variable "imds_http_tokens" {
  description = "IMDS token requirement."
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "optional"], var.imds_http_tokens)
    error_message = "imds_http_tokens must be required or optional."
  }
}

variable "imds_http_endpoint" {
  description = "Whether the instance metadata endpoint is enabled."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_http_endpoint)
    error_message = "imds_http_endpoint must be enabled or disabled."
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
  description = "Whether instance tags are exposed through IMDS."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_instance_metadata_tags)
    error_message = "imds_instance_metadata_tags must be enabled or disabled."
  }
}

variable "imds_http_protocol_ipv6" {
  description = "Whether IMDS supports IPv6."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.imds_http_protocol_ipv6)
    error_message = "imds_http_protocol_ipv6 must be enabled or disabled."
  }
}

variable "target_group_arns" {
  description = "ALB or NLB target group ARNs attached to the Auto Scaling group."
  type        = set(string)
  default     = []
}

variable "health_check_type" {
  description = "Optional EC2 or ELB health-check type. Null selects ELB when target groups are attached and EC2 otherwise."
  type        = string
  default     = null

  validation {
    condition     = var.health_check_type == null || contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be null, EC2, or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Seconds before Auto Scaling begins evaluating instance health."
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0
    error_message = "health_check_grace_period must be zero or greater."
  }
}

variable "default_instance_warmup" {
  description = "Default instance warmup period used by scaling policies."
  type        = number
  default     = 300

  validation {
    condition     = var.default_instance_warmup >= 0
    error_message = "default_instance_warmup must be zero or greater."
  }
}

variable "enable_instance_refresh" {
  description = "Whether launch-template and configured trigger changes start a rolling instance refresh."
  type        = bool
  default     = true
}

variable "instance_refresh" {
  description = "Rolling instance refresh preferences."
  type = object({
    auto_rollback                = optional(bool, true)
    instance_warmup              = optional(number)
    min_healthy_percentage       = optional(number, 100)
    max_healthy_percentage       = optional(number, 110)
    scale_in_protected_instances = optional(string, "Wait")
    skip_matching                = optional(bool, false)
    standby_instances            = optional(string, "Wait")
    triggers                     = optional(set(string), [])
  })
  default = {}

  validation {
    condition = (
      var.instance_refresh.min_healthy_percentage >= 0 &&
      var.instance_refresh.min_healthy_percentage <= 100 &&
      var.instance_refresh.max_healthy_percentage >= 100 &&
      var.instance_refresh.max_healthy_percentage <= 200 &&
      var.instance_refresh.max_healthy_percentage - var.instance_refresh.min_healthy_percentage <= 100 &&
      coalesce(try(var.instance_refresh.instance_warmup, null), 0) >= 0 &&
      contains(["Ignore", "Refresh", "Wait"], var.instance_refresh.scale_in_protected_instances) &&
      contains(["Ignore", "Terminate", "Wait"], var.instance_refresh.standby_instances) &&
      alltrue([for trigger in var.instance_refresh.triggers : contains(["tag"], trigger)])
    )
    error_message = "instance_refresh contains invalid healthy percentages, protected/standby behavior, or triggers."
  }
}

variable "mixed_instances_policy" {
  description = "Optional mixed On-Demand and Spot instance policy."
  type = object({
    on_demand_allocation_strategy            = optional(string, "prioritized")
    on_demand_base_capacity                  = optional(number, 1)
    on_demand_percentage_above_base_capacity = optional(number, 100)
    spot_allocation_strategy                 = optional(string, "price-capacity-optimized")
    spot_instance_pools                      = optional(number)
    spot_max_price                           = optional(string)
    overrides = list(object({
      instance_type     = string
      weighted_capacity = optional(string)
    }))
  })
  default = null

  validation {
    condition = var.mixed_instances_policy == null || (
      length(var.mixed_instances_policy.overrides) >= 2 &&
      length(var.mixed_instances_policy.overrides) == length(distinct([
        for override in var.mixed_instances_policy.overrides : override.instance_type
      ])) &&
      var.mixed_instances_policy.on_demand_base_capacity >= 0 &&
      var.mixed_instances_policy.on_demand_percentage_above_base_capacity >= 0 &&
      var.mixed_instances_policy.on_demand_percentage_above_base_capacity <= 100 &&
      contains(["lowest-price", "prioritized"], var.mixed_instances_policy.on_demand_allocation_strategy) &&
      contains(["capacity-optimized", "capacity-optimized-prioritized", "lowest-price", "price-capacity-optimized"], var.mixed_instances_policy.spot_allocation_strategy) &&
      alltrue([for override in var.mixed_instances_policy.overrides : length(trimspace(override.instance_type)) > 0])
    )
    error_message = "mixed_instances_policy requires at least two valid instance overrides and supported allocation settings."
  }
}

variable "capacity_rebalance" {
  description = "Whether at-risk Spot Instances are proactively replaced."
  type        = bool
  default     = true
}

variable "cpu_target_value" {
  description = "Average ASG CPU utilization target. Null disables CPU target tracking."
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target_value == null || (var.cpu_target_value > 0 && var.cpu_target_value <= 100)
    error_message = "cpu_target_value must be null or between 0 and 100."
  }
}

variable "alb_request_count_target_value" {
  description = "Optional ALB requests-per-target scaling target."
  type        = number
  default     = null

  validation {
    condition     = var.alb_request_count_target_value == null || var.alb_request_count_target_value > 0
    error_message = "alb_request_count_target_value must be null or greater than zero."
  }
}

variable "alb_resource_label" {
  description = "Combined ALB and target-group ARN suffixes required for request-count target tracking."
  type        = string
  default     = null
}

variable "disable_scale_in" {
  description = "Whether target-tracking policies may scale in."
  type        = bool
  default     = false
}

variable "protect_from_scale_in" {
  description = "Whether newly launched instances are protected from scale in."
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "Ordered instance termination policies."
  type        = list(string)
  default     = ["OldestLaunchTemplate", "Default"]
}

variable "enabled_metrics" {
  description = "Auto Scaling group metrics enabled at one-minute granularity."
  type        = set(string)
  default = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]
}

variable "service_linked_role_arn" {
  description = "Optional Auto Scaling service-linked role ARN."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to launch-template and Auto Scaling resources."
  type        = map(string)
  default     = {}
}
