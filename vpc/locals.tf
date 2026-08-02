locals {
  public_subnets = {
    for index, cidr in var.public_subnet_cidrs : try(var.availability_zones[index], "invalid-${index}") => {
      availability_zone = try(var.availability_zones[index], "invalid-${index}")
      cidr_block        = cidr
    }
  }

  private_subnets = {
    for index, cidr in var.private_subnet_cidrs : try(var.availability_zones[index], "invalid-${index}") => {
      availability_zone = try(var.availability_zones[index], "invalid-${index}")
      cidr_block        = cidr
    }
  }

  isolated_subnets = {
    for index, cidr in var.isolated_subnet_cidrs : try(var.availability_zones[index], "invalid-${index}") => {
      availability_zone = try(var.availability_zones[index], "invalid-${index}")
      cidr_block        = cidr
    }
  }

  nat_gateway_zones = var.nat_gateway_mode == "per_az" ? toset(var.availability_zones) : (
    var.nat_gateway_mode == "single" ? toset([var.availability_zones[0]]) : toset([])
  )

  all_subnet_cidrs = concat(
    var.public_subnet_cidrs,
    var.private_subnet_cidrs,
    var.isolated_subnet_cidrs
  )

  common_tags = merge(var.tags, {
    Module        = "vpc"
    ModuleVersion = "1.0.0"
  })
}

check "subnet_counts_match_availability_zones" {
  assert {
    condition = alltrue([
      for cidrs in [
        var.public_subnet_cidrs,
        var.private_subnet_cidrs,
        var.isolated_subnet_cidrs
      ] : length(cidrs) == 0 || length(cidrs) == length(var.availability_zones)
    ])
    error_message = "Each non-empty subnet CIDR list must contain exactly one CIDR per availability zone."
  }
}

check "subnet_cidrs_are_unique" {
  assert {
    condition     = length(local.all_subnet_cidrs) == length(distinct(local.all_subnet_cidrs))
    error_message = "Subnet CIDR blocks must be unique across all subnet tiers."
  }
}

check "at_least_one_subnet" {
  assert {
    condition     = length(local.all_subnet_cidrs) > 0
    error_message = "At least one public, private, or isolated subnet CIDR must be supplied."
  }
}

check "internet_gateway_has_public_subnets" {
  assert {
    condition     = !var.create_internet_gateway || length(var.public_subnet_cidrs) > 0
    error_message = "create_internet_gateway requires public_subnet_cidrs."
  }
}

check "nat_gateway_configuration" {
  assert {
    condition = var.nat_gateway_mode == "none" || (
      var.create_internet_gateway &&
      length(var.public_subnet_cidrs) == length(var.availability_zones) &&
      length(var.private_subnet_cidrs) == length(var.availability_zones)
    )
    error_message = "NAT gateways require create_internet_gateway and one public and private subnet per availability zone."
  }
}

check "gateway_endpoints_have_route_tables" {
  assert {
    condition = length(var.gateway_endpoints) == 0 || (
      length(var.private_subnet_cidrs) + length(var.isolated_subnet_cidrs) > 0
    )
    error_message = "gateway_endpoints require at least one private or isolated subnet route table."
  }
}

check "gateway_endpoint_policies_match_endpoints" {
  assert {
    condition = alltrue([
      for service in keys(var.gateway_endpoint_policies) : contains(var.gateway_endpoints, service)
    ])
    error_message = "Each gateway_endpoint_policies key must also be enabled in gateway_endpoints."
  }
}
