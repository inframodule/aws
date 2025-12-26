# Windows Example

This example deploys Windows EC2 instances with RDP access enabled via the module security group.

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
- Use a Windows AMI ID in `ami_id`.
- `allowed_cidr_blocks` controls RDP (3389) access; keep it as narrow as possible.
- `allow_public_ip` must be true to set `associate_public_ip_address = true`.
