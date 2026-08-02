variable "identifier" {
  description = "RDS DB instance identifier."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.identifier)) && !strcontains(var.identifier, "--")
    error_message = "identifier must be 2-63 lowercase alphanumeric or hyphen characters, begin with a letter, end alphanumeric, and not contain consecutive hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID used by the managed security group."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Private subnet IDs spanning at least two Availability Zones."
  type        = list(string)

  validation {
    condition     = length(distinct(var.subnet_ids)) >= 2 && alltrue([for id in var.subnet_ids : can(regex("^subnet-[0-9a-f]+$", id))])
    error_message = "subnet_ids must contain at least two distinct subnet IDs."
  }
}

variable "create_security_group" {
  description = "Create a database security group with explicit ingress."
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "Existing security group IDs attached in addition to, or instead of, the managed group."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Application security groups allowed to connect to PostgreSQL."
  type        = set(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "Restricted CIDRs allowed to connect to PostgreSQL. Security-group sources are preferred."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : !contains(["0.0.0.0/0", "::/0"], cidr)])
    error_message = "allowed_cidr_blocks cannot contain an internet-wide CIDR."
  }
}

variable "port" {
  description = "PostgreSQL listener port."
  type        = number
  default     = 5432

  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "port must be between 1024 and 65535."
  }
}

variable "database_name" {
  description = "Optional initial database name."
  type        = string
  default     = null

  validation {
    condition     = var.database_name == null || can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must begin with a letter and contain at most 63 alphanumeric or underscore characters."
  }
}

variable "master_username" {
  description = "Master username. The password is generated and managed by RDS in Secrets Manager."
  type        = string
  default     = "dbadmin"
}

variable "master_user_secret_kms_key_id" {
  description = "Optional KMS key ID or ARN encrypting the RDS-managed master secret."
  type        = string
  default     = null
}

variable "engine_version" {
  description = "PostgreSQL major or exact engine version."
  type        = string
  default     = "17"
}

variable "parameter_group_family" {
  description = "PostgreSQL parameter group family matching engine_version."
  type        = string
  default     = "postgres17"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB; zero disables autoscaling."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be gp2, gp3, io1, or io2."
  }
}

variable "iops" {
  description = "Provisioned IOPS for supported storage configurations."
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Provisioned gp3 throughput in MiB/s when supported."
  type        = number
  default     = null
}

variable "kms_key_id" {
  description = "Optional customer-managed KMS key for database storage. AWS-managed encryption is used otherwise."
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Enable a synchronous Multi-AZ standby."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Automated backup retention in days."
  type        = number
  default     = 14

  validation {
    condition     = var.backup_retention_period >= 7 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 7 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred UTC backup window."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred UTC maintenance window."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
  default     = true
}

variable "allow_deletion_protection_disable" {
  description = "Explicit guardrail for disabling deletion protection."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Requires explicit acknowledgement."
  type        = bool
  default     = false
}

variable "allow_skip_final_snapshot" {
  description = "Explicit guardrail acknowledging destroy without a final snapshot."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier when skip_final_snapshot is false."
  type        = string
  default     = null
}

variable "delete_automated_backups" {
  description = "Delete retained automated backups when the instance is destroyed."
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication."
  type        = bool
  default     = true
}

variable "create_parameter_group" {
  description = "Create a PostgreSQL parameter group with enforced TLS and connection logging."
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Existing parameter group name when managed creation is disabled."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Additional PostgreSQL parameters. Secure parameters cannot be overridden."
  type = map(object({
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = {}
}

variable "enabled_cloudwatch_logs_exports" {
  description = "RDS logs exported to CloudWatch Logs."
  type        = set(string)
  default     = ["postgresql", "upgrade"]
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch Logs retention."
  type        = number
  default     = 90
}

variable "cloudwatch_log_kms_key_id" {
  description = "Optional KMS key ARN for exported log groups."
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "performance_insights_kms_key_id" {
  description = "Optional KMS key ARN for Performance Insights."
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days."
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds; zero disables it."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for Enhanced Monitoring."
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Automatically install minor engine updates during the maintenance window."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply eligible modifications immediately instead of in the maintenance window."
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Allow major PostgreSQL upgrades."
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "Optional RDS CA certificate identifier."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
