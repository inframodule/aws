# Production HA RDS PostgreSQL

Deploys a private Multi-AZ PostgreSQL database with 35-day backup retention, storage autoscaling, customer-managed encryption, long-lived CloudWatch logs, IAM database authentication, Performance Insights, deletion protection, and final-snapshot retention.

Multi-AZ, the larger instance, KMS keys, logs, backups, and Performance Insights can materially increase cost. Validate recovery objectives, restore procedures, regional engine availability, quotas, and application connection failover before production use.
