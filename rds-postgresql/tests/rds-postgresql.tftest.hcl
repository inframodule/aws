mock_provider "aws" {}

variables {
  identifier                 = "test-postgresql"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-0123456789abcdef0", "subnet-11111111111111111"]
  allowed_security_group_ids = ["sg-0123456789abcdef0"]
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The database must be private by default."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted
    error_message = "Storage encryption must be enabled."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "RDS must manage the master password."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection
    error_message = "Deletion protection must be enabled."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 14
    error_message = "Default backup retention must be 14 days."
  }

  assert {
    condition     = aws_db_instance.this.multi_az == false
    error_message = "The cost-conscious baseline must not enable Multi-AZ implicitly."
  }

  assert {
    condition     = one([for item in aws_db_parameter_group.this[0].parameter : item if item.name == "rds.force_ssl"]).value == "1"
    error_message = "TLS must be enforced."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 2
    error_message = "PostgreSQL and upgrade log groups must be managed."
  }
}

run "production_ha" {
  command = plan

  variables {
    multi_az                = true
    backup_retention_period = 35
    instance_class          = "db.r7g.large"
    kms_key_id              = "arn:aws:kms:us-east-1:111122223333:key/11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = aws_db_instance.this.multi_az
    error_message = "Production HA must enable Multi-AZ."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 35
    error_message = "Production retention must be configurable to 35 days."
  }
}

run "external_security_group" {
  command = plan

  variables {
    create_security_group = false
    security_group_ids    = ["sg-11111111111111111"]
  }

  assert {
    condition     = length(aws_security_group.this) == 0
    error_message = "Managed security group must not be created."
  }
}

run "reject_public_cidr" {
  command = plan

  variables {
    allowed_cidr_blocks = ["0.0.0.0/0"]
  }

  expect_failures = [var.allowed_cidr_blocks]
}

run "reject_unguarded_deletion_protection_disable" {
  command = plan

  variables {
    deletion_protection = false
  }

  expect_failures = [aws_db_instance.this]
}

run "guarded_deletion_protection_disable" {
  command = plan

  variables {
    deletion_protection               = false
    allow_deletion_protection_disable = true
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == false
    error_message = "The explicit deletion guardrail must work."
  }
}

run "reject_unguarded_final_snapshot_skip" {
  command = plan

  variables {
    skip_final_snapshot = true
  }

  expect_failures = [aws_db_instance.this]
}

run "reject_invalid_storage_autoscaling" {
  command = plan

  variables {
    allocated_storage     = 100
    max_allocated_storage = 50
  }

  expect_failures = [aws_db_instance.this]
}

run "reject_monitoring_without_role" {
  command = plan

  variables {
    monitoring_interval = 60
  }

  expect_failures = [aws_db_instance.this]
}
