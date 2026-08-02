resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.identifier}-db-"
  description = "Restricted PostgreSQL access for ${var.identifier}."
  vpc_id      = var.vpc_id

  tags = merge(local.module_tags, {
    Name = "${var.identifier}-db"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = var.create_security_group ? var.allowed_security_group_ids : []

  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  description                  = "PostgreSQL from ${each.value}."
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port

  tags = local.module_tags
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = var.create_security_group ? var.allowed_cidr_blocks : []

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = strcontains(each.value, ":") ? null : each.value
  cidr_ipv6         = strcontains(each.value, ":") ? each.value : null
  description       = "PostgreSQL from restricted CIDR."
  ip_protocol       = "tcp"
  from_port         = var.port
  to_port           = var.port

  tags = local.module_tags
}
