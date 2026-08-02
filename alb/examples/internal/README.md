# Internal HTTPS ALB example

Creates an HTTPS-only internal Application Load Balancer across private subnets. An optional port 80 listener redirects to HTTPS. Ingress is limited to declared client security groups, and egress is limited to the target security group on application and health-check ports.

Supply an ACM certificate, VPC and private subnet outputs, the client security groups, and the backend security group before planning.

```shell
terraform init
terraform plan
```
