# Basic Example

This example provisions one or more EC2 instances in a VPC using the compute module.

## Prerequisites
- Terraform >= 1.5.0
- AWS credentials configured (env vars, shared config, or SSO)

## Usage
1) Copy the example inputs and fill in real values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2) Initialize and plan:

```bash
terraform init
terraform plan
```

3) Apply and destroy:

```bash
terraform apply
terraform destroy
```

## Notes
- `allowed_cidr_blocks` controls SSH (22) and RDP (3389) access when the module creates the security group.
- IMDSv2 is enforced by default (`imds_http_tokens = "required"`).
- `allow_public_ip` must be true to set `associate_public_ip_address = true`.
