mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    name                              = "application"
    ami_id                            = "ami-0123456789abcdef0"
    instance_type                     = "t3.micro"
    subnet_ids                        = ["subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_id                            = "vpc-0123456789abcdef0"
    ingress_source_security_group_ids = ["sg-11111111111111111"]
    egress_ipv4_cidrs                 = ["0.0.0.0/0"]
    target_group_arns                 = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/application/1111111111111111"]
  }

  assert {
    condition = (
      aws_launch_template.this.metadata_options[0].http_tokens == "required" &&
      aws_launch_template.this.metadata_options[0].http_put_response_hop_limit == 1 &&
      aws_launch_template.this.metadata_options[0].instance_metadata_tags == "disabled"
    )
    error_message = "The launch template must retain hardened IMDS defaults."
  }

  assert {
    condition = (
      !aws_launch_template.this.network_interfaces[0].associate_public_ip_address &&
      aws_launch_template.this.monitoring[0].enabled
    )
    error_message = "Instances must have no public IP and detailed monitoring must be enabled."
  }

  assert {
    condition = (
      aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted &&
      aws_launch_template.this.block_device_mappings[0].ebs[0].volume_type == "gp3"
    )
    error_message = "The root volume must use encrypted gp3 storage."
  }

  assert {
    condition = (
      aws_autoscaling_group.this.min_size == 2 &&
      aws_autoscaling_group.this.desired_capacity == 2 &&
      aws_autoscaling_group.this.max_size == 4 &&
      aws_autoscaling_group.this.health_check_type == "ELB"
    )
    error_message = "The group must retain its highly available capacity and ELB health-check defaults."
  }

  assert {
    condition = (
      aws_autoscaling_group.this.instance_refresh[0].preferences[0].min_healthy_percentage == 100 &&
      aws_autoscaling_group.this.instance_refresh[0].preferences[0].max_healthy_percentage == 110 &&
      aws_autoscaling_group.this.instance_refresh[0].preferences[0].auto_rollback
    )
    error_message = "Rolling refresh must launch replacements before terminating capacity and enable rollback."
  }

  assert {
    condition     = length(aws_autoscaling_policy.cpu) == 1
    error_message = "CPU target tracking must be enabled by default."
  }

  assert {
    condition = (
      length(aws_vpc_security_group_ingress_rule.security_group) == 1 &&
      length(aws_vpc_security_group_egress_rule.ipv4) == 1
    )
    error_message = "Managed networking must include only explicitly declared ingress and egress."
  }
}

run "mixed_capacity" {
  command = plan

  variables {
    name                              = "mixed-application"
    ami_id                            = "ami-0123456789abcdef0"
    instance_type                     = "t3.small"
    subnet_ids                        = ["subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_id                            = "vpc-0123456789abcdef0"
    ingress_source_security_group_ids = ["sg-11111111111111111"]
    egress_ipv4_cidrs                 = ["0.0.0.0/0"]
    mixed_instances_policy = {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 25
      overrides = [
        { instance_type = "t3.small" },
        { instance_type = "t3a.small" },
        { instance_type = "t4g.small" }
      ]
    }
  }

  assert {
    condition     = length(aws_autoscaling_group.this.mixed_instances_policy) == 1
    error_message = "A mixed instances policy must be created when configured."
  }

  assert {
    condition = (
      aws_autoscaling_group.this.capacity_rebalance &&
      aws_autoscaling_group.this.mixed_instances_policy[0].instances_distribution[0].spot_allocation_strategy == "price-capacity-optimized"
    )
    error_message = "Mixed capacity must use proactive rebalancing and the price-capacity-optimized Spot strategy."
  }

  assert {
    condition     = length(aws_autoscaling_group.this.mixed_instances_policy[0].launch_template[0].override) == 3
    error_message = "Every diversified instance override must be preserved."
  }
}

run "external_security_groups" {
  command = plan

  variables {
    name                  = "external-networking"
    ami_id                = "ami-0123456789abcdef0"
    instance_type         = "t3.micro"
    subnet_ids            = ["subnet-11111111111111111", "subnet-22222222222222222"]
    create_security_group = false
    security_group_ids    = ["sg-11111111111111111"]
  }

  assert {
    condition     = length(aws_security_group.this) == 0
    error_message = "The module must not create a security group when management is disabled."
  }

  assert {
    condition     = length(aws_launch_template.this.network_interfaces[0].security_groups) == 1
    error_message = "External security groups must be attached to the launch template."
  }
}

run "reject_public_ip_without_guardrail" {
  command = plan

  variables {
    name                        = "invalid-public-ip"
    ami_id                      = "ami-0123456789abcdef0"
    instance_type               = "t3.micro"
    subnet_ids                  = ["subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_id                      = "vpc-0123456789abcdef0"
    ingress_ipv4_cidrs          = ["10.0.0.0/16"]
    egress_ipv4_cidrs           = ["0.0.0.0/0"]
    associate_public_ip_address = true
  }

  expect_failures = [check.public_ip_guardrail]
}

run "reject_invalid_capacity" {
  command = plan

  variables {
    name                  = "invalid-capacity"
    ami_id                = "ami-0123456789abcdef0"
    instance_type         = "t3.micro"
    subnet_ids            = ["subnet-11111111111111111", "subnet-22222222222222222"]
    create_security_group = false
    security_group_ids    = ["sg-11111111111111111"]
    min_size              = 3
    desired_capacity      = 2
    max_size              = 4
  }

  expect_failures = [check.capacity_bounds]
}
