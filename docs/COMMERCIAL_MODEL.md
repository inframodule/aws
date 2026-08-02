# Commercial Model

This document records the public-safe commercialization strategy for the module library. Confidential pricing, customer details, margins, and sales plans do not belong in this public repository.

## Positioning

The public modules are the trust and adoption layer. They demonstrate implementation quality, security posture, documentation, testing, and maintenance discipline.

The business does not depend on charging for individual Terraform files. It monetizes complete outcomes:

- Architecture and implementation.
- Opinionated private blueprints.
- Environment-specific integration.
- Security and cost reviews.
- Upgrades and compatibility assurance.
- Drift detection and operational support.
- Training and handoff.

## Product layers

```text
Public module library
    reusable AWS primitives
              │
              ▼
Private solution blueprints
    tested compositions and automation
              │
              ▼
Customer deployments
    configuration, migration, and integration
              │
              ▼
Managed operations
    upgrades, monitoring, reviews, and support
```

### Public module library

The public repository contains reusable primitives such as VPC, ALB, S3, Auto Scaling, RDS, and container infrastructure. Public modules should be useful independently and remain well tested.

### Private solution blueprints

Private, paid blueprints compose the public modules into maintained solutions. They can be distributed through private Git repositories or a private module registry. HCP Terraform and Terraform Enterprise support access-controlled private modules and versioned distribution; see the [private registry documentation](https://developer.hashicorp.com/terraform/cloud-docs/registry).

Candidate blueprints:

- Secure AWS Foundation.
- Highly Available Web Application.
- Backup and Disaster Recovery Baseline.
- Regulated Data Storage.
- Container Application Platform.
- EKS Growth Platform.

Private blueprints may contain organization-specific policy, CI/CD pipelines, policy-as-code, cost checks, observability, upgrade automation, and operational runbooks.

### Professional services

Offer fixed-scope or custom services around the blueprints:

- AWS environment assessment.
- Foundation implementation.
- Application migration.
- Security hardening.
- Cost optimization.
- Disaster-recovery design and testing.
- Infrastructure-as-code training.

AWS Marketplace supports professional-services categories including assessments, implementation, managed services, premium support, and training. Marketplace can be evaluated after repeatable offers and customer references exist. See the [AWS Marketplace professional services guide](https://docs.aws.amazon.com/marketplace/latest/userguide/proserv-getting-started.html).

### Managed operations

Recurring support is the strongest long-term revenue layer because infrastructure requires continuous maintenance.

Candidate managed services:

- Terraform and AWS provider upgrades.
- Module compatibility testing.
- Monthly security and cost review.
- Drift and failed-deployment investigation.
- Backup and restore verification.
- Kubernetes and managed add-on upgrades.
- Defined response windows and advisory support.

Service levels, exclusions, and response commitments must be written into customer agreements rather than implied by the public repository.

## Initial customer offers

### Secure AWS Foundation

Target: a small business beginning or correcting its AWS deployment.

Includes account and access review, VPC, centralized storage/logging, budgets, baseline monitoring, backup recommendations, documentation, and handoff.

### Highly Available Web Application

Target: a business that needs a reliable web workload without operating Kubernetes.

Includes VPC, ALB, Auto Scaling, RDS, S3, certificates, DNS, backups, monitoring, and deployment documentation.

### Managed Infrastructure Care

Target: a business without a dedicated platform team.

Includes scheduled dependency upgrades, security and cost review, drift investigation, backup review, and an agreed support channel.

### EKS Growth Platform

Target: organizations that genuinely need Kubernetes APIs, ecosystem tooling, workload portability, or multiple container teams.

Includes a secure EKS baseline, managed add-ons, identity, observability, upgrade planning, cost controls, and ongoing platform maintenance. It is not the default recommendation for a small workload that can run effectively on ECS/Fargate or EC2 Auto Scaling.

## Repository boundary

Keep these items public:

- Reusable modules.
- Examples that contain no customer information.
- Security and support policies.
- Compatibility and upgrade guidance.
- High-level roadmap and product positioning.

Keep these items private:

- Customer configurations and state.
- Credentials, account IDs, internal domains, and network ranges.
- Detailed pricing and margins.
- Sales pipeline and customer records.
- Proprietary blueprint automation.
- Contractual service levels and internal runbooks.

## Success measures

Track whether the public project produces business value through:

- Module adoption and qualified inquiries.
- Repeated customer architecture patterns.
- Time required to deliver a new environment.
- Upgrade and support effort per customer.
- Conversion from assessment to implementation.
- Conversion from implementation to managed support.
- Customer retention and successful restore or upgrade exercises.

Do not optimize solely for stars, downloads, or the number of modules. The goal is dependable customer outcomes with a maintainable product surface.
