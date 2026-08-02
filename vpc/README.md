# AWS Secure VPC Module

Version: **1.0.0**

Terraform module for an IPv4 AWS VPC with explicit subnet tiers, secure defaults, optional NAT egress, gateway endpoints, and VPC Flow Logs.

## Security defaults

- No internet gateway or NAT gateway unless explicitly enabled.
- Public IPv4 assignment is disabled on every subnet tier by default.
- The default security group has no ingress or egress rules.
- VPC Flow Logs capture all traffic and retain logs for 365 days.
- An S3 gateway endpoint provides private S3 routing by default.
- Isolated route tables never receive an internet or NAT default route.
- VPC DNS support, DNS hostnames, and network address usage metrics are enabled.
- IPv6 is intentionally outside the 1.0.0 scope.

Flow Logs are encrypted using CloudWatch Logs server-side encryption by default. Supply `flow_log_kms_key_id` to use a customer-managed KMS key. Gateway endpoints use the AWS default endpoint policy unless a JSON policy is supplied in `gateway_endpoint_policies`.

## Usage

### Secure baseline

The following complete root configuration creates private and isolated subnets in two availability zones. It has no internet gateway, NAT gateway, or automatic public IP assignment. Flow Logs and private S3 routing are enabled by the module defaults.

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "git::https://github.com/inframodule/aws.git//vpc?ref=vpc-v1.0.0"

  name               = "application"
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  private_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
  isolated_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
```

Save the configuration as `main.tf`, authenticate the AWS provider, and run:

```shell
terraform init
terraform plan
terraform apply
```

### Production high availability

To add controlled internet egress, create public subnets and select the `per_az` NAT topology:

```hcl
module "vpc" {
  source = "git::https://github.com/inframodule/aws.git//vpc?ref=vpc-v1.0.0"

  name               = "application"
  vpc_cidr           = "10.20.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs   = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  isolated_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]

  create_internet_gateway = true
  nat_gateway_mode         = "per_az"
  gateway_endpoints        = ["s3", "dynamodb"]

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

Every non-empty subnet CIDR list must contain exactly one entry per availability zone. Keeping CIDR allocation explicit prevents subnet addresses from changing when callers revise the topology.

## NAT modes

| Mode | Behavior | Typical use |
|---|---|---|
| `none` | No NAT gateways or private default routes | Restricted or endpoint-only workloads |
| `single` | One NAT gateway in the first availability zone | Development and cost-sensitive environments |
| `per_az` | One NAT gateway per availability zone | Production high availability |

NAT gateways incur AWS hourly and data-processing charges. Both NAT modes require an internet gateway plus public and private subnets in every configured availability zone.

## Examples

- `examples/secure-baseline`: private and isolated subnets with no internet path.
- `examples/production-ha`: three subnet tiers and a NAT gateway per availability zone.

## Inputs

| Input | Default | Description |
|---|---:|---|
| `name` | required | Resource name and Name-tag prefix |
| `vpc_cidr` | required | VPC IPv4 CIDR |
| `availability_zones` | required | Ordered availability zones |
| `public_subnet_cidrs` | `[]` | Public CIDRs ordered to match the availability zones |
| `private_subnet_cidrs` | `[]` | Private CIDRs ordered to match the availability zones |
| `isolated_subnet_cidrs` | `[]` | Isolated CIDRs ordered to match the availability zones |
| `create_internet_gateway` | `false` | Creates an IGW and public default routes |
| `nat_gateway_mode` | `none` | `none`, `single`, or `per_az` |
| `public_subnet_map_public_ip_on_launch` | `false` | Enables automatic public IPv4 assignment in public subnets |
| `enable_flow_logs` | `true` | Sends Flow Logs to CloudWatch Logs |
| `flow_log_traffic_type` | `ALL` | Captures `ACCEPT`, `REJECT`, or `ALL` traffic |
| `flow_log_retention_in_days` | `365` | CloudWatch log retention |
| `flow_log_kms_key_id` | `null` | Optional customer-managed KMS key ARN for Flow Logs |
| `gateway_endpoints` | `["s3"]` | S3 and/or DynamoDB gateway endpoints |
| `gateway_endpoint_policies` | `{}` | Optional JSON endpoint policies keyed by service |
| `enable_network_address_usage_metrics` | `true` | Enables VPC IP address usage metrics |
| `tags` | `{}` | Additional resource tags |

All subnet CIDRs must be valid and unique. AWS additionally rejects subnet ranges outside the VPC CIDR or ranges that overlap an existing subnet.

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr` | VPC IPv4 CIDR |
| `default_security_group_id` | Locked-down default security group ID |
| `internet_gateway_id` | Internet gateway ID or `null` |
| `public_subnet_ids` | Public subnet IDs keyed by availability zone |
| `private_subnet_ids` | Private subnet IDs keyed by availability zone |
| `isolated_subnet_ids` | Isolated subnet IDs keyed by availability zone |
| `public_route_table_ids` | Public route table IDs keyed by availability zone |
| `private_route_table_ids` | Private route table IDs keyed by availability zone |
| `isolated_route_table_ids` | Isolated route table IDs keyed by availability zone |
| `nat_gateway_ids` | NAT gateway IDs keyed by availability zone |
| `nat_gateway_public_ips` | NAT public IPs keyed by availability zone |
| `gateway_endpoint_ids` | Endpoint IDs keyed by service |
| `flow_log_id` | Flow Log ID or `null` |
| `flow_log_group_arn` | Flow Logs log group ARN or `null` |

## Testing

```shell
terraform fmt -check -recursive
terraform -chdir=vpc init -backend=false
terraform -chdir=vpc validate
terraform -chdir=vpc test
```

The native tests use a mocked AWS provider and do not create infrastructure.

## Versioning

The module version is recorded in `VERSION` and resource tags. Release this module with a scoped Git tag such as `vpc-v1.0.0`, then reference that immutable tag from callers.
