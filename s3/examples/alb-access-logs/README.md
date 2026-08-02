# ALB access-log bucket example

Creates an SSE-S3 encrypted bucket with the required Elastic Load Balancing service-principal policy, then configures the repository's ALB module to deliver logs to it. The bucket and ALB use the same AWS provider region.

AWS supports only SSE-S3 encryption for Application Load Balancer access-log buckets. The policy limits delivery to the current account's `AWSLogs` path.

```shell
terraform init
terraform plan -var-file=terraform.tfvars
```

The example creates billable S3 and Application Load Balancer resources when applied.
