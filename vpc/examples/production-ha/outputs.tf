output "vpc_id" {
  description = "ID of the example VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  value       = module.vpc.private_subnet_ids
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs keyed by availability zone."
  value       = module.vpc.isolated_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "NAT gateway public IPv4 addresses keyed by availability zone."
  value       = module.vpc.nat_gateway_public_ips
}
