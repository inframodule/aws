# Secure baseline RDS PostgreSQL

Deploys a private, encrypted single-instance PostgreSQL database suitable for development or smaller non-critical workloads. RDS manages the master password in Secrets Manager. Supply a VPC, at least two private subnets, and the application security group that requires port 5432 access.

This example retains automated backups for 14 days and enables deletion protection. It does not create a Multi-AZ standby; use the production example for that availability level.
