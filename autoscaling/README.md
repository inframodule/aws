# AWS Secure EC2 Auto Scaling Module

Version: **1.0.0**

Terraform module for highly available EC2 Auto Scaling groups with hardened launch templates, rolling instance refresh, target-group integration, target-tracking scaling, and optional mixed On-Demand and Spot capacity.

## Security and availability defaults

- Requires at least two private subnets.
- Disables public IPv4 assignment unless an explicit guardrail is enabled.
- Requires IMDSv2 and uses an IMDS hop limit of one.
- Disables instance-tag and IPv6 metadata access.
- Encrypts root and additional EBS volumes.
- Uses gp3 storage with deletion on termination.
- Enables EC2 detailed monitoring.
- Requires explicit managed security-group ingress and egress.
- Maintains at least two instances by default.
- Uses launch-before-terminate rolling refresh with automatic rollback.
- Uses an exact launch-template version rather than `$Latest` or `$Default`.
- Enables CPU target tracking at 60 percent by default.
- Ignores later `desired_capacity` drift so Terraform does not fight scaling policies.

AWS instance refresh replaces instances in controlled batches and can launch replacements before terminating existing capacity when the minimum healthy percentage is 100. See the [AWS instance refresh documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/instance-refresh-overview.html).

## Basic usage

This example creates a private, multi-AZ group with managed networking and CPU target tracking:

```hcl
module "autoscaling" {
  source = "git::https://github.com/inframodule/aws.git//autoscaling?ref=autoscaling-v1.0.0"

  name          = "application"
  ami_id        = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
  subnet_ids    = values(module.vpc.private_subnet_ids)

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_id             = module.vpc.vpc_id
  application_port   = 8080
  ingress_ipv4_cidrs = [module.vpc.vpc_cidr]

  # Restrict this further to a proxy, firewall, or endpoint range when possible.
  egress_ipv4_cidrs = ["0.0.0.0/0"]
  egress_from_port  = 443
  egress_to_port    = 443

  iam_instance_profile_name = aws_iam_instance_profile.application.name
  user_data                  = file("${path.module}/bootstrap.sh")

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

The module base64-encodes `user_data`. Do not place secrets in user data because Terraform stores the value in state; retrieve secrets at runtime through an IAM role and a managed secret service.

## ALB integration

Create the application security group outside both modules to avoid a dependency cycle. The ALB can then restrict egress to that group, while a separate rule permits inbound traffic only from the ALB security group.

```hcl
resource "aws_security_group" "application" {
  name_prefix = "application-"
  description = "Application instances behind the ALB."
  vpc_id      = module.vpc.vpc_id
}

module "alb" {
  source = "git::https://github.com/inframodule/aws.git//alb?ref=alb-v1.0.0"

  name                  = "application"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = values(module.vpc.public_subnet_ids)
  internal              = false
  allow_internet_facing = true
  certificate_arn       = var.certificate_arn

  ingress_ipv4_cidrs               = ["0.0.0.0/0"]
  egress_target_security_group_ids = [aws_security_group.application.id]
  target_port                       = 8080
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "application_https" {
  security_group_id = aws_security_group.application.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

module "autoscaling" {
  source = "git::https://github.com/inframodule/aws.git//autoscaling?ref=autoscaling-v1.0.0"

  name          = "application"
  ami_id        = var.ami_id
  instance_type = "t3.small"
  subnet_ids    = values(module.vpc.private_subnet_ids)

  create_security_group = false
  security_group_ids    = [aws_security_group.application.id]

  target_group_arns = [module.alb.target_group_arn]
  application_port  = 8080

  cpu_target_value                   = 60
  alb_request_count_target_value     = 1000
  alb_resource_label = "${module.alb.load_balancer_arn_suffix}/${module.alb.target_group_arn_suffix}"
}
```

When several target-tracking policies exist, Auto Scaling scales out if any policy needs additional capacity and scales in only when all scale-in-enabled policies agree.

## Mixed On-Demand and Spot capacity

Use several compatible instance types to improve Spot capacity availability:

```hcl
module "mixed_autoscaling" {
  source = "git::https://github.com/inframodule/aws.git//autoscaling?ref=autoscaling-v1.0.0"

  # Other required inputs omitted.

  instance_type = "m6i.large"
  mixed_instances_policy = {
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 25
    spot_allocation_strategy                 = "price-capacity-optimized"
    overrides = [
      { instance_type = "m6i.large" },
      { instance_type = "m6a.large" },
      { instance_type = "m5.large" }
    ]
  }

  capacity_rebalance = true
}
```

Capacity rebalancing proactively replaces Spot Instances that receive an interruption-risk recommendation. See the [AWS capacity rebalancing documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html).

Every override must be compatible with the AMI, architecture, networking, block devices, and application. Capacity values represent units rather than instance counts when weighted capacity is used.

## Rolling refresh behavior

Launch-template changes automatically start an instance refresh. Defaults keep 100 percent healthy capacity and allow temporary growth to 110 percent. `skip_matching` is false so user-data-only application changes are not accidentally skipped.

```hcl
  instance_refresh = {
    auto_rollback          = true
    min_healthy_percentage = 100
    max_healthy_percentage = 120
    instance_warmup        = 300
    skip_matching          = false
  }
```

Auto rollback and temporary replacement capacity can increase availability but may temporarily increase EC2 cost. Protected or standby instances can also delay a refresh.

## Inputs

### Core capacity and compute

| Input | Default | Description |
|---|---:|---|
| `name` | required | ASG and resource name prefix |
| `ami_id` | required | Launch-template AMI ID |
| `instance_type` | required | Default EC2 instance type |
| `subnet_ids` | required | At least two private subnet IDs |
| `min_size` | `2` | Minimum capacity |
| `desired_capacity` | `2` | Initial desired capacity |
| `max_size` | `4` | Maximum capacity |
| `key_name` | `null` | Optional EC2 key pair |
| `iam_instance_profile_name` | `null` | Optional instance profile |
| `user_data` | `null` | Plain-text bootstrap data, base64-encoded by the module |
| `enable_detailed_monitoring` | `true` | Enables EC2 detailed monitoring |
| `ebs_optimized` | `null` | Overrides the instance-type EBS optimization default |

### Networking

| Input | Default | Description |
|---|---:|---|
| `create_security_group` | `true` | Creates a managed instance security group |
| `vpc_id` | `null` | VPC for the managed security group |
| `security_group_ids` | `[]` | Additional or externally managed groups |
| `application_port` | `8080` | Managed ingress application port |
| `ingress_ipv4_cidrs` | `[]` | Allowed IPv4 sources |
| `ingress_ipv6_cidrs` | `[]` | Allowed IPv6 sources |
| `ingress_source_security_group_ids` | `[]` | Allowed source security groups |
| `egress_ipv4_cidrs` | `[]` | Allowed IPv4 destinations |
| `egress_ipv6_cidrs` | `[]` | Allowed IPv6 destinations |
| `egress_destination_security_group_ids` | `[]` | Allowed destination security groups |
| `egress_from_port` | `443` | First managed egress TCP port |
| `egress_to_port` | `443` | Last managed egress TCP port |
| `associate_public_ip_address` | `false` | Assigns public IPv4 addresses |
| `allow_public_ip` | `false` | Required guardrail for public IP assignment |

### Storage and metadata

| Input | Default | Description |
|---|---:|---|
| `root_device_name` | `/dev/xvda` | Root device name |
| `root_block_device` | encrypted 20 GiB gp3 | Root volume settings |
| `ebs_block_devices` | `[]` | Additional EBS volumes |
| `require_volume_encryption` | `true` | Enforces encryption on all declared volumes |
| `kms_key_id` | `null` | Optional EBS KMS key |
| `imds_http_tokens` | `required` | IMDSv2 token requirement |
| `imds_http_endpoint` | `enabled` | Metadata endpoint status |
| `imds_http_put_response_hop_limit` | `1` | Metadata response hop limit |
| `imds_instance_metadata_tags` | `disabled` | Exposes tags through metadata |
| `imds_http_protocol_ipv6` | `disabled` | Enables IPv6 metadata access |

### Health, updates, and scaling

| Input | Default | Description |
|---|---:|---|
| `target_group_arns` | `[]` | Attached ALB/NLB target groups |
| `health_check_type` | derived | ELB with target groups, otherwise EC2 |
| `health_check_grace_period` | `300` | Initial health-check grace period |
| `default_instance_warmup` | `300` | Default metric warmup |
| `enable_instance_refresh` | `true` | Enables rolling refresh |
| `instance_refresh` | launch-before-terminate | Refresh percentages and behavior |
| `mixed_instances_policy` | `null` | Optional On-Demand/Spot distribution and overrides |
| `capacity_rebalance` | `true` | Proactively replaces at-risk Spot Instances |
| `cpu_target_value` | `60` | CPU target; `null` disables it |
| `alb_request_count_target_value` | `null` | Optional requests-per-target scaling target |
| `alb_resource_label` | `null` | Required ALB/TG suffix label for request scaling |
| `disable_scale_in` | `false` | Prevents target tracking from scaling in |
| `protect_from_scale_in` | `false` | Protects newly launched instances from scale in |
| `termination_policies` | oldest template, default | Instance termination order |
| `enabled_metrics` | core ASG metrics | One-minute group metrics |
| `service_linked_role_arn` | `null` | Optional service-linked role ARN |
| `tags` | `{}` | Additional propagated tags |

## Outputs

| Output | Description |
|---|---|
| `autoscaling_group_id` | Auto Scaling group ID |
| `autoscaling_group_name` | Auto Scaling group name |
| `autoscaling_group_arn` | Auto Scaling group ARN |
| `launch_template_id` | Launch template ID |
| `launch_template_arn` | Launch template ARN |
| `launch_template_latest_version` | Exact latest template version |
| `security_group_id` | Managed security group ID or `null` |
| `security_group_ids` | All instance security group IDs |
| `cpu_scaling_policy_arn` | CPU policy ARN or `null` |
| `alb_request_count_scaling_policy_arn` | Request-count policy ARN or `null` |

## Examples

- `examples/secure-baseline`: private On-Demand group with managed networking.
- `examples/mixed-capacity`: diversified On-Demand and Spot capacity.

## Cost considerations

- The group launches at least two instances by default.
- Detailed monitoring and additional CloudWatch metrics may incur charges.
- Instance refresh can temporarily exceed desired capacity.
- Spot lowers compute price but instances can be interrupted.
- EBS volumes, KMS requests, NAT traffic, and ALB usage are billed separately.

Review the plan and current AWS pricing before applying production configurations.

## Testing

```shell
terraform fmt -check -recursive
terraform -chdir=autoscaling init -backend=false
terraform -chdir=autoscaling validate
terraform -chdir=autoscaling test
```

The native tests use a mocked AWS provider and create no infrastructure.

## Versioning

The module version is recorded in `VERSION` and resource tags. Release it with a scoped Git tag such as `autoscaling-v1.0.0`, then reference that immutable tag from callers.
