# AWS Secure Application Load Balancer Module

Version: **1.0.0**

Terraform module for an HTTPS-first AWS Application Load Balancer with secure defaults, restricted managed security-group rules, target registration, optional access logs, and optional AWS WAF integration.

## Security defaults

- Creates an internal load balancer unless public exposure is explicitly authorized.
- Requires an ACM certificate and always creates an HTTPS listener.
- Redirects HTTP to HTTPS by default.
- Uses AWS's recommended `ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09` policy by default.
- Enables deletion protection, invalid-header dropping, strictest desync mitigation, and HTTP/2.
- Keeps WAF fail-open behavior disabled.
- Adds no unrestricted managed security-group rules implicitly.
- Limits managed egress to declared target security groups or CIDRs and target/health-check ports.

The target security group should allow inbound application and health-check traffic only from the ALB security group. See the [AWS recommended ALB security-group rules](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html).

## Usage

The following example creates a public HTTPS ALB using outputs from the repository's `vpc` module. The EC2 targets should be in private subnets.

```hcl
module "alb" {
  source = "git::https://github.com/inframodule/aws.git//alb?ref=alb-v1.0.0"

  name                  = "application"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = values(module.vpc.public_subnet_ids)
  internal              = false
  allow_internet_facing = true
  certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-1111-1111-1111-111111111111"

  ingress_ipv4_cidrs               = ["0.0.0.0/0"]
  egress_target_security_group_ids = [aws_security_group.application.id]

  target_port = 8080
  targets = {
    for id in module.compute.instance_ids : id => {
      id = id
    }
  }

  health_check = {
    path = "/health/ready"
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = module.alb.security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
```

Use the same target security group in the `compute.security_group_ids` input. The ALB module controls outbound access to the targets, while the target rule above ensures that the application port accepts traffic only from the ALB.

## Internal ALB

For service-to-service traffic, retain `internal = true` and permit only known client security groups:

```hcl
module "internal_alb" {
  source = "git::https://github.com/inframodule/aws.git//alb?ref=alb-v1.0.0"

  name            = "private-api"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = values(module.vpc.private_subnet_ids)
  certificate_arn = var.internal_certificate_arn

  ingress_source_security_group_ids = [aws_security_group.client.id]
  egress_target_security_group_ids  = [aws_security_group.application.id]

  target_port = 8080
}
```

## Access logs and WAF

The module does not create an S3 bucket or WAF policy. Supply existing resources when required:

```hcl
  access_logs = {
    bucket = aws_s3_bucket.alb_logs.id
    prefix = "alb/application"
  }

  web_acl_arn = aws_wafv2_web_acl.application.arn
```

The S3 bucket must have an appropriate Elastic Load Balancing delivery policy. Keeping log storage and WAF policy outside this module allows separate retention, encryption, and governance controls.

## Inputs

| Input | Default | Description |
|---|---:|---|
| `name` | required | ALB name, limited to 32 valid characters |
| `vpc_id` | required | VPC for the ALB and target group |
| `subnet_ids` | required | At least two subnet IDs in distinct availability zones |
| `internal` | `true` | Creates an internal ALB |
| `allow_internet_facing` | `false` | Guardrail required before setting `internal = false` |
| `ip_address_type` | `ipv4` | ALB IP address type |
| `certificate_arn` | required | Primary ACM certificate ARN |
| `additional_certificate_arns` | `[]` | Additional HTTPS listener certificates |
| `https_listener_port` | `443` | HTTPS listener port |
| `enable_http_redirect` | `true` | Creates HTTP-to-HTTPS redirect listener |
| `http_listener_port` | `80` | HTTP redirect listener port |
| `ssl_policy` | PQ-TLS policy | HTTPS TLS security policy |
| `create_security_group` | `true` | Creates a managed ALB security group |
| `security_group_ids` | `[]` | Additional or externally managed security groups |
| `ingress_ipv4_cidrs` | `[]` | Allowed listener-source IPv4 CIDRs |
| `ingress_ipv6_cidrs` | `[]` | Allowed listener-source IPv6 CIDRs |
| `ingress_source_security_group_ids` | `[]` | Allowed listener-source security groups |
| `egress_ipv4_cidrs` | `[]` | Allowed backend destination IPv4 CIDRs |
| `egress_ipv6_cidrs` | `[]` | Allowed backend destination IPv6 CIDRs |
| `egress_target_security_group_ids` | `[]` | Allowed backend destination security groups |
| `target_port` | `80` | Backend application port |
| `target_protocol` | `HTTP` | `HTTP` or `HTTPS` backend protocol |
| `target_protocol_version` | `HTTP1` | `HTTP1`, `HTTP2`, or `GRPC` |
| `target_type` | `instance` | `instance` or `ip` targets |
| `targets` | `{}` | Target registrations keyed by stable caller names |
| `health_check` | secure defaults | Health-check protocol, port, path, matcher, and thresholds |
| `deregistration_delay` | `300` | Target deregistration delay in seconds |
| `slow_start` | `0` | Target slow-start period |
| `load_balancing_algorithm_type` | `round_robin` | Target selection algorithm |
| `stickiness` | `null` | Optional load-balancer cookie stickiness |
| `enable_deletion_protection` | `true` | Protects the ALB from accidental deletion |
| `drop_invalid_header_fields` | `true` | Removes invalid HTTP headers |
| `desync_mitigation_mode` | `strictest` | HTTP desync protection mode |
| `enable_http2` | `true` | Enables HTTP/2 clients |
| `enable_waf_fail_open` | `false` | Routes traffic if WAF is unavailable |
| `idle_timeout` | `60` | Idle connection timeout in seconds |
| `access_logs` | `null` | Existing S3 access-log destination |
| `web_acl_arn` | `null` | Existing WAFv2 web ACL ARN |
| `tags` | `{}` | Additional resource tags |

## Outputs

| Output | Description |
|---|---|
| `load_balancer_id` | ALB ID |
| `load_balancer_arn` | ALB ARN |
| `load_balancer_arn_suffix` | ALB CloudWatch metric suffix |
| `dns_name` | ALB DNS name |
| `zone_id` | Route 53 alias zone ID |
| `security_group_id` | Managed security group ID or `null` |
| `security_group_ids` | All security groups associated with the ALB |
| `target_group_arn` | Target group ARN |
| `target_group_arn_suffix` | Target group CloudWatch metric suffix |
| `https_listener_arn` | HTTPS listener ARN |
| `http_redirect_listener_arn` | HTTP redirect listener ARN or `null` |

## Examples

- `examples/internal`: internal HTTPS ALB with security-group-based client access.
- `examples/public-https`: guarded internet-facing HTTPS ALB with optional logs and WAF.

## Testing

```shell
terraform fmt -check -recursive
terraform -chdir=alb init -backend=false
terraform -chdir=alb validate
terraform -chdir=alb test
```

The native tests use a mocked AWS provider and create no infrastructure.

## Versioning

The module version is recorded in `VERSION` and resource tags. Release it with a scoped Git tag such as `alb-v1.0.0`, then reference that immutable tag from callers.
