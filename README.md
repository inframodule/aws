# AWS Terraform Modules

Reusable Terraform modules for AWS infrastructure.

The public modules are secure, composable infrastructure primitives. The project roadmap prioritizes a production web platform first, followed by lower-operations container support and an opinionated EKS platform.

## Modules

- [`alb`](alb/README.md): HTTPS-first Application Load Balancer with restricted networking, target registration, and optional WAF integration.
- [`autoscaling`](autoscaling/README.md): hardened EC2 Auto Scaling with rolling refresh, target tracking, and optional mixed Spot capacity.
- [`compute`](compute/README.md): EC2 instances with optional security groups and IMDSv2 hardening.
- [`s3`](s3/README.md): private, versioned object storage with explicit encryption, transport controls, lifecycle management, and policy composition.
- [`vpc`](vpc/README.md): secure multi-AZ VPC networking with subnet tiers, optional NAT, gateway endpoints, and Flow Logs.

## Project documentation

- [Commercial model](docs/COMMERCIAL_MODEL.md)
- [Security policy](SECURITY.md)
- [Support policy](SUPPORT.md)
- [Apache License 2.0](LICENSE)
