locals {
  listener_ports = toset(concat(
    [var.https_listener_port],
    var.enable_http_redirect ? [var.http_listener_port] : []
  ))

  health_check_port = var.health_check.port == "traffic-port" ? var.target_port : try(tonumber(var.health_check.port), var.target_port)
  target_ports      = toset([var.target_port, local.health_check_port])

  ingress_cidr_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_ipv4_cidrs) :
    "${pair[0]}-${pair[1]}" => {
      port = pair[0]
      cidr = pair[1]
    }
  }

  ingress_security_group_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_source_security_group_ids) :
    "${pair[0]}-${pair[1]}" => {
      port              = pair[0]
      security_group_id = pair[1]
    }
  }

  ingress_ipv6_rules = {
    for pair in setproduct(local.listener_ports, var.ingress_ipv6_cidrs) :
    "${pair[0]}-${pair[1]}" => {
      port = pair[0]
      cidr = pair[1]
    }
  }

  egress_cidr_rules = {
    for pair in setproduct(local.target_ports, var.egress_ipv4_cidrs) :
    "${pair[0]}-${pair[1]}" => {
      port = pair[0]
      cidr = pair[1]
    }
  }

  egress_security_group_rules = {
    for pair in setproduct(local.target_ports, var.egress_target_security_group_ids) :
    "${pair[0]}-${pair[1]}" => {
      port              = pair[0]
      security_group_id = pair[1]
    }
  }

  egress_ipv6_rules = {
    for pair in setproduct(local.target_ports, var.egress_ipv6_cidrs) :
    "${pair[0]}-${pair[1]}" => {
      port = pair[0]
      cidr = pair[1]
    }
  }

  managed_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : []
  effective_security_group_ids = concat(
    local.managed_security_group_ids,
    tolist(var.security_group_ids)
  )

  common_tags = merge(var.tags, {
    Module        = "alb"
    ModuleVersion = "1.0.0"
  })
}

check "internet_facing_guardrail" {
  assert {
    condition     = var.internal || var.allow_internet_facing
    error_message = "allow_internet_facing must be true before internal can be set to false."
  }
}

check "listener_ports_are_distinct" {
  assert {
    condition     = !var.enable_http_redirect || var.http_listener_port != var.https_listener_port
    error_message = "http_listener_port and https_listener_port must differ when HTTP redirect is enabled."
  }
}

check "security_group_configuration" {
  assert {
    condition = var.create_security_group ? (
      length(var.ingress_ipv4_cidrs) + length(var.ingress_ipv6_cidrs) + length(var.ingress_source_security_group_ids) > 0 &&
      length(var.egress_ipv4_cidrs) + length(var.egress_ipv6_cidrs) + length(var.egress_target_security_group_ids) > 0
    ) : length(var.security_group_ids) > 0
    error_message = "A managed security group requires ingress and egress destinations; otherwise security_group_ids must be supplied."
  }
}
