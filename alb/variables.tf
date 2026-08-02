variable "name" {
  description = "Name of the Application Load Balancer."
  type        = string

  validation {
    condition = (
      length(var.name) > 0 &&
      length(var.name) <= 32 &&
      !startswith(lower(var.name), "internal-") &&
      can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$", var.name))
    )
    error_message = "name must be 1-32 alphanumeric or hyphen characters, cannot begin or end with a hyphen, and cannot begin with internal-."
  }
}

variable "vpc_id" {
  description = "ID of the VPC containing the load balancer and target group."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must be non-empty."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the load balancer. Application Load Balancers require subnets in at least two availability zones."
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

variable "internal" {
  description = "Whether the load balancer is internal."
  type        = bool
  default     = true
}

variable "allow_internet_facing" {
  description = "Guardrail that must be enabled before internal can be set to false."
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "IP address type for the load balancer."
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack", "dualstack-without-public-ipv4"], var.ip_address_type)
    error_message = "ip_address_type must be ipv4, dualstack, or dualstack-without-public-ipv4."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", var.certificate_arn))
    error_message = "certificate_arn must be a valid ACM certificate ARN."
  }
}

variable "additional_certificate_arns" {
  description = "Additional ACM certificate ARNs to associate with the HTTPS listener."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.additional_certificate_arns : can(regex("^arn:[^:]+:acm:[^:]+:[0-9]{12}:certificate/.+$", arn))
    ])
    error_message = "Every additional_certificate_arns entry must be a valid ACM certificate ARN."
  }
}

variable "https_listener_port" {
  description = "Port for the HTTPS listener."
  type        = number
  default     = 443

  validation {
    condition     = var.https_listener_port >= 1 && var.https_listener_port <= 65535
    error_message = "https_listener_port must be between 1 and 65535."
  }
}

variable "enable_http_redirect" {
  description = "Whether to redirect HTTP requests to HTTPS."
  type        = bool
  default     = true
}

variable "http_listener_port" {
  description = "Port for the optional HTTP redirect listener."
  type        = number
  default     = 80

  validation {
    condition     = var.http_listener_port >= 1 && var.http_listener_port <= 65535
    error_message = "http_listener_port must be between 1 and 65535."
  }
}

variable "ssl_policy" {
  description = "TLS security policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"

  validation {
    condition     = length(trimspace(var.ssl_policy)) > 0
    error_message = "ssl_policy must be non-empty."
  }
}

variable "create_security_group" {
  description = "Whether to create a managed security group for the load balancer."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "Additional security group IDs to associate with the load balancer."
  type        = set(string)
  default     = []
}

variable "ingress_ipv4_cidrs" {
  description = "IPv4 CIDRs allowed to reach the managed security group listener ports."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.ingress_ipv4_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every ingress_ipv4_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "ingress_source_security_group_ids" {
  description = "Security group IDs allowed to reach the managed security group listener ports."
  type        = set(string)
  default     = []
}

variable "ingress_ipv6_cidrs" {
  description = "IPv6 CIDRs allowed to reach the managed security group listener ports."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ingress_ipv6_cidrs : can(cidrhost(cidr, 0)) && can(regex(":", cidr))
    ])
    error_message = "Every ingress_ipv6_cidrs entry must be a valid IPv6 CIDR."
  }
}

variable "egress_ipv4_cidrs" {
  description = "IPv4 CIDRs the managed security group may reach on target and health-check ports."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.egress_ipv4_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every egress_ipv4_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "egress_target_security_group_ids" {
  description = "Target security group IDs the managed security group may reach on target and health-check ports."
  type        = set(string)
  default     = []
}

variable "egress_ipv6_cidrs" {
  description = "IPv6 CIDRs the managed security group may reach on target and health-check ports."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.egress_ipv6_cidrs : can(cidrhost(cidr, 0)) && can(regex(":", cidr))
    ])
    error_message = "Every egress_ipv6_cidrs entry must be a valid IPv6 CIDR."
  }
}

variable "target_port" {
  description = "Port on which targets receive traffic."
  type        = number
  default     = 80

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
  }
}

variable "target_protocol" {
  description = "Protocol used to route traffic to targets."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_protocol)
    error_message = "target_protocol must be HTTP or HTTPS."
  }
}

variable "target_protocol_version" {
  description = "Protocol version used with targets."
  type        = string
  default     = "HTTP1"

  validation {
    condition     = contains(["HTTP1", "HTTP2", "GRPC"], var.target_protocol_version)
    error_message = "target_protocol_version must be HTTP1, HTTP2, or GRPC."
  }
}

variable "target_type" {
  description = "Target group target type."
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip"], var.target_type)
    error_message = "target_type must be instance or ip."
  }
}

variable "targets" {
  description = "Targets to register, keyed by a caller-selected stable name."
  type = map(object({
    id                = string
    port              = optional(number)
    availability_zone = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for target in values(var.targets) : (
        length(trimspace(target.id)) > 0 &&
        (try(target.port, null) == null || (target.port >= 1 && target.port <= 65535))
      )
    ])
    error_message = "Each target requires a non-empty id and an optional port between 1 and 65535."
  }
}

variable "health_check" {
  description = "Target group health-check configuration."
  type = object({
    enabled             = optional(bool, true)
    healthy_threshold   = optional(number, 3)
    interval            = optional(number, 30)
    matcher             = optional(string, "200-399")
    path                = optional(string, "/")
    port                = optional(string, "traffic-port")
    protocol            = optional(string, "HTTP")
    timeout             = optional(number, 5)
    unhealthy_threshold = optional(number, 3)
  })
  default = {}

  validation {
    condition = (
      contains(["HTTP", "HTTPS"], var.health_check.protocol) &&
      startswith(var.health_check.path, "/") &&
      (var.health_check.port == "traffic-port" || try(
        tonumber(var.health_check.port) >= 1 && tonumber(var.health_check.port) <= 65535,
        false
      )) &&
      var.health_check.healthy_threshold >= 2 && var.health_check.healthy_threshold <= 10 &&
      var.health_check.unhealthy_threshold >= 2 && var.health_check.unhealthy_threshold <= 10 &&
      var.health_check.interval >= 5 && var.health_check.interval <= 300 &&
      var.health_check.timeout >= 2 && var.health_check.timeout <= 120 &&
      var.health_check.timeout < var.health_check.interval
    )
    error_message = "health_check contains an invalid protocol, path, port, threshold, interval, or timeout."
  }
}

variable "deregistration_delay" {
  description = "Seconds to wait before deregistering a target."
  type        = number
  default     = 300

  validation {
    condition     = var.deregistration_delay >= 0 && var.deregistration_delay <= 3600
    error_message = "deregistration_delay must be between 0 and 3600."
  }
}

variable "slow_start" {
  description = "Seconds during which newly registered targets receive a linearly increasing traffic share. Zero disables slow start."
  type        = number
  default     = 0

  validation {
    condition     = var.slow_start == 0 || (var.slow_start >= 30 && var.slow_start <= 900)
    error_message = "slow_start must be 0 or between 30 and 900."
  }
}

variable "load_balancing_algorithm_type" {
  description = "Target group load-balancing algorithm."
  type        = string
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "least_outstanding_requests", "weighted_random"], var.load_balancing_algorithm_type)
    error_message = "load_balancing_algorithm_type must be round_robin, least_outstanding_requests, or weighted_random."
  }
}

variable "stickiness" {
  description = "Optional load-balancer cookie stickiness configuration."
  type = object({
    enabled         = optional(bool, true)
    cookie_duration = optional(number, 86400)
    cookie_name     = optional(string)
  })
  default = null

  validation {
    condition = var.stickiness == null || (
      var.stickiness.cookie_duration >= 1 &&
      var.stickiness.cookie_duration <= 604800 &&
      (try(var.stickiness.cookie_name, null) == null || length(trimspace(var.stickiness.cookie_name)) > 0)
    )
    error_message = "stickiness.cookie_duration must be between 1 and 604800 and cookie_name must be null or non-empty."
  }
}

variable "enable_deletion_protection" {
  description = "Whether to prevent accidental load balancer deletion."
  type        = bool
  default     = true
}

variable "drop_invalid_header_fields" {
  description = "Whether to remove HTTP headers with invalid fields before routing requests."
  type        = bool
  default     = true
}

variable "desync_mitigation_mode" {
  description = "HTTP desync mitigation mode."
  type        = string
  default     = "strictest"

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "desync_mitigation_mode must be monitor, defensive, or strictest."
  }
}

variable "enable_http2" {
  description = "Whether HTTP/2 is enabled on the load balancer."
  type        = bool
  default     = true
}

variable "enable_waf_fail_open" {
  description = "Whether requests are routed when AWS WAF is unavailable."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Seconds before an idle connection is closed."
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "idle_timeout must be between 1 and 4000."
  }
}

variable "access_logs" {
  description = "Optional ALB access-log configuration. The destination bucket and its policy must already exist."
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string)
  })
  default = null

  validation {
    condition     = var.access_logs == null || length(trimspace(var.access_logs.bucket)) > 0
    error_message = "access_logs.bucket must be non-empty when access logs are configured."
  }
}

variable "web_acl_arn" {
  description = "Optional AWS WAFv2 web ACL ARN to associate with the load balancer."
  type        = string
  default     = null

  validation {
    condition     = var.web_acl_arn == null || can(regex("^arn:[^:]+:wafv2:[^:]+:[0-9]{12}:.+$", var.web_acl_arn))
    error_message = "web_acl_arn must be null or a valid WAFv2 ARN."
  }
}

variable "tags" {
  description = "Additional tags to apply to module resources."
  type        = map(string)
  default     = {}
}
