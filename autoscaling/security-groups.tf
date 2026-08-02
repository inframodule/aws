resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${substr(var.name, 0, 64)}-"
  description = "Managed security group for ${var.name} Auto Scaling instances."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.name}-asg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ipv4" {
  for_each = var.create_security_group ? var.ingress_ipv4_cidrs : []

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${var.application_port} from ${each.value}."
  cidr_ipv4         = each.value
  from_port         = var.application_port
  to_port           = var.application_port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "ipv6" {
  for_each = var.create_security_group ? var.ingress_ipv6_cidrs : []

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${var.application_port} from ${each.value}."
  cidr_ipv6         = each.value
  from_port         = var.application_port
  to_port           = var.application_port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = var.create_security_group ? var.ingress_source_security_group_ids : []

  security_group_id            = aws_security_group.this[0].id
  description                  = "Allow TCP ${var.application_port} from ${each.value}."
  referenced_security_group_id = each.value
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "ipv4" {
  for_each = var.create_security_group ? var.egress_ipv4_cidrs : []

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${var.egress_from_port}-${var.egress_to_port} to ${each.value}."
  cidr_ipv4         = each.value
  from_port         = var.egress_from_port
  to_port           = var.egress_to_port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "ipv6" {
  for_each = var.create_security_group ? var.egress_ipv6_cidrs : []

  security_group_id = aws_security_group.this[0].id
  description       = "Allow TCP ${var.egress_from_port}-${var.egress_to_port} to ${each.value}."
  cidr_ipv6         = each.value
  from_port         = var.egress_from_port
  to_port           = var.egress_to_port
  ip_protocol       = "tcp"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "security_group" {
  for_each = var.create_security_group ? var.egress_destination_security_group_ids : []

  security_group_id            = aws_security_group.this[0].id
  description                  = "Allow TCP ${var.egress_from_port}-${var.egress_to_port} to ${each.value}."
  referenced_security_group_id = each.value
  from_port                    = var.egress_from_port
  to_port                      = var.egress_to_port
  ip_protocol                  = "tcp"

  tags = local.common_tags
}
