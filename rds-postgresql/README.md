# Secure Amazon RDS for PostgreSQL module

Version: **1.0.0**

Creates a private Amazon RDS for PostgreSQL instance with RDS-managed Secrets Manager credentials, encrypted storage, enforced TLS, retained backups, explicit ingress, bounded logging, and guarded destruction.

## Security defaults

- Never creates a publicly accessible database.
- Requires at least two private subnets and creates a DB subnet group.
- Creates an ingress-only security group and rejects internet-wide PostgreSQL CIDRs.
- Encrypts storage and supports customer-managed KMS keys.
- Generates and rotates the master password through RDS and Secrets Manager rather than Terraform input.
- Enables IAM database authentication and enforces TLS with `rds.force_ssl = 1`.
- Logs connections, disconnections, slow statements, PostgreSQL output, and upgrades.
- Enables Performance Insights and retains CloudWatch logs for 90 days.
- Retains automated backups for 14 days and preserves them after instance deletion.
- Enables deletion protection and requires a final snapshot.

The baseline uses a small single-instance class to control development cost. Production workloads should explicitly evaluate Multi-AZ, capacity, storage performance, monitoring, and recovery objectives.

## Basic usage

```hcl
module "postgresql" {
  source = "git::https://github.com/inframodule/aws.git//rds-postgresql?ref=rds-postgresql-v1.0.0"

  identifier    = "application-production"
  database_name = "application"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.autoscaling.security_group_id]

  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  backup_retention_period = 14

  tags = {
    Environment = "production"
    Owner       = "platform"
  }
}
```

Retrieve the generated credential using `master_user_secret_arn`. Grant applications only the Secrets Manager and KMS permissions needed to read it; never copy the password into Terraform inputs or outputs.

## Production Multi-AZ usage

```hcl
module "postgresql" {
  source = "git::https://github.com/inframodule/aws.git//rds-postgresql?ref=rds-postgresql-v1.0.0"

  identifier     = "orders-production"
  database_name  = "orders"
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  instance_class = "db.r7g.large"
  multi_az       = true

  allowed_security_group_ids = [module.autoscaling.security_group_id]

  allocated_storage        = 100
  max_allocated_storage    = 500
  backup_retention_period  = 35
  kms_key_id               = aws_kms_key.database.arn
  master_user_secret_kms_key_id   = aws_kms_key.secrets.arn
  performance_insights_kms_key_id = aws_kms_key.database.arn
  cloudwatch_log_kms_key_id       = aws_kms_key.logs.arn
  cloudwatch_log_retention_days   = 365

  tags = {
    Environment = "production"
    Criticality = "high"
  }
}
```

Multi-AZ maintains a synchronous standby for availability; it is not a read-scaling replica. Test application connection failover and restore procedures.

## Existing security and parameter groups

```hcl
create_security_group = false
security_group_ids    = [aws_security_group.database.id]

create_parameter_group = false
parameter_group_name   = aws_db_parameter_group.organizational.name
```

When using an external parameter group, the caller owns TLS and logging controls.

## Enhanced Monitoring

Enhanced Monitoring is disabled by default because it requires an IAM service role:

```hcl
monitoring_interval = 60
monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
```

CloudWatch log export and Performance Insights are enabled independently.

## Destruction guardrails

Deletion protection is on and a final snapshot is required. Disabling either requires a separate acknowledgement:

```hcl
deletion_protection               = false
allow_deletion_protection_disable = true

skip_final_snapshot       = true
allow_skip_final_snapshot = true
```

Use these settings only for disposable environments. Terraform cannot delete an instance while AWS deletion protection remains enabled, and final snapshot identifiers must be unique.

## Inputs

| Input | Default | Description |
|---|---:|---|
| `identifier` | required | RDS instance identifier |
| `vpc_id` | `null` | VPC for the managed security group |
| `subnet_ids` | required | At least two private subnet IDs |
| `create_security_group` | `true` | Creates the restricted database group |
| `security_group_ids` | `[]` | Existing groups attached to RDS |
| `allowed_security_group_ids` | `[]` | Application groups allowed on PostgreSQL |
| `allowed_cidr_blocks` | `[]` | Restricted PostgreSQL source CIDRs |
| `database_name` | `null` | Optional initial database |
| `master_username` | `dbadmin` | RDS-managed secret username |
| `engine_version` | `17` | PostgreSQL version |
| `instance_class` | `db.t4g.micro` | RDS instance class |
| `allocated_storage` | `20` | Initial GiB |
| `max_allocated_storage` | `100` | Storage autoscaling ceiling |
| `storage_type` | `gp3` | Storage type |
| `kms_key_id` | `null` | Customer-managed storage key |
| `multi_az` | `false` | Synchronous standby |
| `backup_retention_period` | `14` | Automated backup days |
| `deletion_protection` | `true` | Blocks deletion |
| `skip_final_snapshot` | `false` | Omits final snapshot only with guardrail |
| `iam_database_authentication_enabled` | `true` | Enables IAM authentication |
| `enabled_cloudwatch_logs_exports` | PostgreSQL, upgrade | Exported logs |
| `performance_insights_enabled` | `true` | Query performance telemetry |
| `monitoring_interval` | `0` | Enhanced Monitoring interval |
| `auto_minor_version_upgrade` | `true` | Minor updates in maintenance windows |
| `apply_immediately` | `false` | Defers eligible changes to maintenance |

See [variables.tf](variables.tf) for every input and validation.

## Outputs

Exports the instance ID/ARN/resource ID, hostname, endpoint, port, database name, RDS-managed secret ARN, managed security group ID, DB subnet group, and parameter group. The credential value is never output.

## Examples

- [`examples/secure-baseline`](examples/secure-baseline): cost-conscious private development baseline.
- [`examples/production-ha`](examples/production-ha): Multi-AZ production configuration with customer-managed encryption.

## Cost and operations

RDS instance hours, Multi-AZ standby capacity, storage/IOPS, backup storage, snapshots, KMS, logs, monitoring, and transfer can incur charges. Storage autoscaling does not scale down. Configure budgets and alarms, test point-in-time restores, monitor certificates and engine support, and rehearse failover.

## Testing

```shell
terraform fmt -recursive -check
terraform -chdir=rds-postgresql init -backend=false
terraform -chdir=rds-postgresql validate
terraform -chdir=rds-postgresql test
```

The tests mock AWS and create no infrastructure. Release with `rds-postgresql-v1.0.0` and reference that immutable tag.
