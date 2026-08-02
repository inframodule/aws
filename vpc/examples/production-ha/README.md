# Production high-availability example

Creates public, private, and isolated subnets in three availability zones. Each private subnet routes through a NAT gateway in the same zone; isolated subnets have no default route. VPC Flow Logs plus S3 and DynamoDB gateway endpoints are enabled.

```shell
terraform init
terraform plan
```

Applying this example creates three NAT gateways and other billable AWS resources. Review current AWS pricing before deployment.
