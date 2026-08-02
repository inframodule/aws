# Secure baseline example

Creates a two-instance Auto Scaling group across private subnets with encrypted gp3 storage, IMDSv2, detailed monitoring, rolling refresh, and CPU target tracking. Public IP assignment is disabled.

Ingress is restricted to the supplied VPC CIDR on the application port. Egress allows only HTTPS; narrow the destination CIDR further when the workload has a known proxy or VPC endpoint path.

```shell
terraform init
terraform plan -var-file=terraform.tfvars
```
