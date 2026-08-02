# Secure baseline example

Creates a two-AZ VPC with private and isolated subnet tiers, no internet gateway, no NAT gateway, an S3 gateway endpoint, and VPC Flow Logs.

This example deliberately has no general internet ingress or egress path. Add interface or gateway endpoints required by workloads, or select a NAT topology when internet egress is necessary.

```shell
terraform init
terraform plan
```

Applying the example creates billable CloudWatch Logs resources. Supplying a customer-managed KMS key can incur additional KMS charges.
