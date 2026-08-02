mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:test-vpc-flow-logs"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-vpc-flow-logs"
    }
  }
}

run "secure_defaults" {
  command = apply

  variables {
    name                  = "secure-test"
    vpc_cidr              = "10.0.0.0/16"
    availability_zones    = ["us-east-1a", "us-east-1b"]
    private_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
    isolated_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support && aws_vpc.this.enable_dns_hostnames
    error_message = "Secure defaults must enable VPC DNS support and hostnames."
  }

  assert {
    condition     = length(aws_internet_gateway.this) == 0 && length(aws_nat_gateway.this) == 0
    error_message = "Secure defaults must not create internet or NAT gateways."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.private : !subnet.map_public_ip_on_launch])
    error_message = "Private subnets must not assign public IP addresses."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.isolated : !subnet.map_public_ip_on_launch])
    error_message = "Isolated subnets must not assign public IP addresses."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1 && aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Secure defaults must capture all traffic with VPC Flow Logs."
  }

  assert {
    condition     = length(aws_vpc_endpoint.gateway) == 1
    error_message = "The S3 gateway endpoint must be enabled by default."
  }

  assert {
    condition = (
      length(aws_default_security_group.this.ingress) == 0 &&
      length(aws_default_security_group.this.egress) == 0
    )
    error_message = "The default security group must have no ingress or egress rules."
  }
}

run "production_ha" {
  command = plan

  variables {
    name                    = "production-test"
    vpc_cidr                = "10.1.0.0/16"
    availability_zones      = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs     = ["10.1.0.0/24", "10.1.1.0/24"]
    private_subnet_cidrs    = ["10.1.10.0/24", "10.1.11.0/24"]
    isolated_subnet_cidrs   = ["10.1.20.0/24", "10.1.21.0/24"]
    create_internet_gateway = true
    nat_gateway_mode        = "per_az"
    gateway_endpoints       = ["s3", "dynamodb"]
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "per_az mode must create one NAT gateway per availability zone."
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "Each private route table must receive a NAT default route."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.public : !subnet.map_public_ip_on_launch])
    error_message = "Public subnets must retain the secure no-public-IP default."
  }
}

run "single_nat" {
  command = plan

  variables {
    name                    = "single-nat-test"
    vpc_cidr                = "10.3.0.0/16"
    availability_zones      = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs     = ["10.3.0.0/24", "10.3.1.0/24"]
    private_subnet_cidrs    = ["10.3.10.0/24", "10.3.11.0/24"]
    create_internet_gateway = true
    nat_gateway_mode        = "single"
    gateway_endpoints       = []
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single mode must create exactly one NAT gateway."
  }

  assert {
    condition     = length(aws_route.private_nat) == 2
    error_message = "single mode must route every private subnet through the shared NAT gateway."
  }
}

run "reject_mismatched_subnet_counts" {
  command = plan

  variables {
    name                 = "invalid-test"
    vpc_cidr             = "10.2.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    private_subnet_cidrs = ["10.2.0.0/24"]
    gateway_endpoints    = []
    enable_flow_logs     = false
  }

  expect_failures = [check.subnet_counts_match_availability_zones]
}
