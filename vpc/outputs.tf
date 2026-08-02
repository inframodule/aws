output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "default_security_group_id" {
  description = "ID of the locked-down default security group."
  value       = aws_default_security_group.this.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway, or null when disabled."
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = { for zone, subnet in aws_subnet.public : zone => subnet.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = { for zone, subnet in aws_subnet.private : zone => subnet.id }
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs keyed by availability zone."
  value       = { for zone, subnet in aws_subnet.isolated : zone => subnet.id }
}

output "public_route_table_ids" {
  description = "Public route table IDs keyed by availability zone."
  value       = { for zone, route_table in aws_route_table.public : zone => route_table.id }
}

output "private_route_table_ids" {
  description = "Private route table IDs keyed by availability zone."
  value       = { for zone, route_table in aws_route_table.private : zone => route_table.id }
}

output "isolated_route_table_ids" {
  description = "Isolated route table IDs keyed by availability zone."
  value       = { for zone, route_table in aws_route_table.isolated : zone => route_table.id }
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs keyed by availability zone."
  value       = { for zone, gateway in aws_nat_gateway.this : zone => gateway.id }
}

output "nat_gateway_public_ips" {
  description = "NAT gateway public IPv4 addresses keyed by availability zone."
  value       = { for zone, address in aws_eip.nat : zone => address.public_ip }
}

output "gateway_endpoint_ids" {
  description = "Gateway VPC endpoint IDs keyed by service name."
  value       = { for service, endpoint in aws_vpc_endpoint.gateway : service => endpoint.id }
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log, or null when disabled."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch log group, or null when disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}
