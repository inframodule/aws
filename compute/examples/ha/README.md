# HA Example

This example deploys multiple EC2 instances across multiple subnets (typically different AZs).

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
- Provide at least two subnets in different AZs for higher availability.
- `allowed_cidr_blocks` controls SSH (22) and RDP (3389) access when the module creates the security group.
- `allow_public_ip` must be true to set `associate_public_ip_address = true`.
