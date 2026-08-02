resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${substr(var.name, 0, 32)}-"
  description = "Managed security group for ${var.name} Application Load Balancer."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = var.create_security_group ? local.ingress_cidr_rules : {}

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${each.value.port} from ${each.value.cidr}."
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = var.create_security_group ? local.ingress_security_group_rules : {}

  security_group_id            = aws_security_group.this[0].id
  description                  = "Allow TCP ${each.value.port} from ${each.value.security_group_id}."
  referenced_security_group_id = each.value.security_group_id
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "ipv6" {
  for_each = var.create_security_group ? local.ingress_ipv6_rules : {}

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${each.value.port} from ${each.value.cidr}."
  cidr_ipv6         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "cidr" {
  for_each = var.create_security_group ? local.egress_cidr_rules : {}

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${each.value.port} to ${each.value.cidr}."
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "security_group" {
  for_each = var.create_security_group ? local.egress_security_group_rules : {}

  security_group_id            = aws_security_group.this[0].id
  description                  = "Allow TCP ${each.value.port} to ${each.value.security_group_id}."
  referenced_security_group_id = each.value.security_group_id
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "ipv6" {
  for_each = var.create_security_group ? local.egress_ipv6_rules : {}

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${each.value.port} to ${each.value.cidr}."
  cidr_ipv6         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = local.common_tags
}
