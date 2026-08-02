# Mixed On-Demand and Spot example

Creates a diversified group using compatible x86_64 instance types, one base On-Demand capacity unit, 25 percent On-Demand capacity above the base, and price-capacity-optimized Spot allocation. Capacity rebalancing proactively replaces Spot Instances at elevated interruption risk.

Confirm that the selected AMI supports every instance type and that all overrides provide comparable application capacity.

```shell
terraform init
terraform plan -var-file=terraform.tfvars
```
