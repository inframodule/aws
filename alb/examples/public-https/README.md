# Public HTTPS ALB example

Creates an internet-facing Application Load Balancer across public subnets. Port 80 redirects to HTTPS, backend egress is limited to the target security group, and optional access logging and WAF integration are available.

The target instances should reside in private subnets. Their security group must allow the application and health-check ports from the module's `security_group_id` output.

```shell
terraform init
terraform plan
```

An Application Load Balancer, access-log storage, WAF, and related traffic can incur AWS charges.
