# AWS Compute Module

Terraform module to deploy one or more EC2 instances into a VPC, with optional security group creation and IMDSv2 hardening.

## Features
- Single or multiple instances across subnets (round-robin placement).
- Optional security group with SSH (22) and RDP (3389) ingress.
- IMDSv2 controls with optional instance metadata tags and IPv6 support.
- Root and additional EBS block device configuration.

## Usage
```hcl
module "compute" {
  source = "./modules/aws/compute"

  name_prefix                 = "compute"
  instance_count              = 2
  ami_id                      = "ami-0123456789abcdef0"
  instance_type               = "t3.micro"
  vpc_id                      = "vpc-0123456789abcdef0"
  subnet_ids                  = ["subnet-aaaabbbbccccdddd0", "subnet-11112222333344440"]
  allowed_cidr_blocks         = ["203.0.113.0/24"]
  associate_public_ip_address = true
  allow_public_ip             = true

  imds_http_tokens                 = "required"
  imds_http_endpoint               = "enabled"
  imds_http_put_response_hop_limit = 1
  imds_instance_metadata_tags      = "disabled"
  imds_http_protocol_ipv6          = "disabled"

  require_volume_encryption = true
  kms_key_id                = null
  enable_ssh                = true
  enable_rdp                = true

  root_block_device = {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    iops                  = 3000
    throughput            = 125
  }

  ebs_block_device = [
    {
      device_name           = "/dev/sdf"
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
      iops                  = 3000
      throughput            = 125
    }
  ]

  tags = {
    Environment = "dev"
    Owner       = "platform"
  }
}
```

## Examples
- `examples/basic` for a minimal Linux deployment.
- `examples/ha` for multi-subnet (multi-AZ) placement.
- `examples/windows` for RDP-focused Windows hosts.

## Testing and Linting
- `terraform fmt -recursive` to format.
- `terraform validate` to validate module and examples.
- `tflint --recursive` for static analysis. On Ubuntu, install via `sudo snap install tflint`.
- `go test ./tests -v` for Terratest plan-only checks (requires env vars).

## Notes
- If `create_security_group` is true, `vpc_id` and `allowed_cidr_blocks` are required.
- Volume encryption is controlled per device via `encrypted` fields.
- `allow_public_ip` must be true to set `associate_public_ip_address = true`.
- Use `enable_ssh` and `enable_rdp` to limit ingress when using the managed security group.
- Terratest env vars: `AWS_REGION`, `VPC_ID`, `SUBNET_IDS`, `ALLOWED_CIDR_BLOCKS`, `AMI_ID`, `WINDOWS_AMI_ID`.
