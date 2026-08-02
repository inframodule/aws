mock_provider "aws" {}

run "secure_internal_defaults" {
  command = plan

  variables {
    name                             = "private-app"
    vpc_id                           = "vpc-0123456789abcdef0"
    subnet_ids                       = ["subnet-11111111111111111", "subnet-22222222222222222"]
    certificate_arn                  = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-1111-1111-1111-111111111111"
    ingress_ipv4_cidrs               = ["10.0.0.0/16"]
    egress_target_security_group_ids = ["sg-0123456789abcdef0"]
    targets = {
      app_1 = { id = "i-11111111111111111" }
      app_2 = { id = "i-22222222222222222" }
    }
  }

  assert {
    condition     = aws_lb.this.internal
    error_message = "The load balancer must be internal by default."
  }

  assert {
    condition = (
      aws_lb.this.enable_deletion_protection &&
      aws_lb.this.drop_invalid_header_fields &&
      aws_lb.this.desync_mitigation_mode == "strictest" &&
      !aws_lb.this.enable_waf_fail_open
    )
    error_message = "The load balancer security defaults must remain enabled."
  }

  assert {
    condition     = aws_lb_listener.https.protocol == "HTTPS" && aws_lb_listener.https.port == 443
    error_message = "The primary listener must use HTTPS on port 443."
  }

  assert {
    condition     = aws_lb_listener.https.ssl_policy == "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
    error_message = "The HTTPS listener must use the secure default TLS policy."
  }

  assert {
    condition     = length(aws_lb_listener.http_redirect) == 1
    error_message = "HTTP-to-HTTPS redirect must be enabled by default."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.cidr) == 2
    error_message = "The managed security group must allow the declared CIDR on HTTP and HTTPS listener ports."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.security_group) == 1
    error_message = "Managed egress must be restricted to the target security group and target port."
  }

  assert {
    condition     = length(aws_lb_target_group_attachment.this) == 2
    error_message = "Every declared target must be registered."
  }
}

run "public_https" {
  command = plan

  variables {
    name                             = "public-app"
    vpc_id                           = "vpc-0123456789abcdef0"
    subnet_ids                       = ["subnet-11111111111111111", "subnet-22222222222222222"]
    internal                         = false
    allow_internet_facing            = true
    ip_address_type                  = "dualstack"
    certificate_arn                  = "arn:aws:acm:us-east-1:123456789012:certificate/22222222-2222-2222-2222-222222222222"
    ingress_ipv4_cidrs               = ["0.0.0.0/0"]
    ingress_ipv6_cidrs               = ["::/0"]
    egress_target_security_group_ids = ["sg-0123456789abcdef0"]
    health_check = {
      path = "/health/ready"
      port = "8080"
    }
  }

  assert {
    condition     = !aws_lb.this.internal
    error_message = "The load balancer must be internet-facing when explicitly authorized."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ipv6) == 2
    error_message = "Dual-stack ingress must allow the declared IPv6 CIDR on both listener ports."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.security_group) == 2
    error_message = "A distinct health-check port must receive a separate restricted egress rule."
  }
}

run "external_security_groups" {
  command = plan

  variables {
    name                  = "external-sg-app"
    vpc_id                = "vpc-0123456789abcdef0"
    subnet_ids            = ["subnet-11111111111111111", "subnet-22222222222222222"]
    certificate_arn       = "arn:aws:acm:us-east-1:123456789012:certificate/33333333-3333-3333-3333-333333333333"
    create_security_group = false
    security_group_ids    = ["sg-11111111111111111", "sg-22222222222222222"]
  }

  assert {
    condition     = length(aws_security_group.this) == 0
    error_message = "The module must not create a security group when management is disabled."
  }

  assert {
    condition     = length(aws_lb.this.security_groups) == 2
    error_message = "All external security groups must be associated with the load balancer."
  }
}

run "reject_unguarded_public_alb" {
  command = plan

  variables {
    name                             = "unguarded-app"
    vpc_id                           = "vpc-0123456789abcdef0"
    subnet_ids                       = ["subnet-11111111111111111", "subnet-22222222222222222"]
    internal                         = false
    certificate_arn                  = "arn:aws:acm:us-east-1:123456789012:certificate/44444444-4444-4444-4444-444444444444"
    ingress_ipv4_cidrs               = ["0.0.0.0/0"]
    egress_target_security_group_ids = ["sg-0123456789abcdef0"]
  }

  expect_failures = [check.internet_facing_guardrail]
}
