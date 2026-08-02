# AWS Terraform Modules

Reusable Terraform modules for AWS infrastructure.

## Modules

- [`alb`](alb/README.md): HTTPS-first Application Load Balancer with restricted networking, target registration, and optional WAF integration.
- [`compute`](compute/README.md): EC2 instances with optional security groups and IMDSv2 hardening.
- [`s3`](s3/README.md): private, versioned object storage with explicit encryption, transport controls, lifecycle management, and policy composition.
- [`vpc`](vpc/README.md): secure multi-AZ VPC networking with subnet tiers, optional NAT, gateway endpoints, and Flow Logs.
