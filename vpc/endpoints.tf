data "aws_region" "current" {}

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.gateway_endpoints

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  policy            = lookup(var.gateway_endpoint_policies, each.key, null)
  route_table_ids = concat(
    [for route_table in aws_route_table.private : route_table.id],
    [for route_table in aws_route_table.isolated : route_table.id]
  )

  tags = merge(local.common_tags, {
    Name = "${var.name}-${each.key}-endpoint"
  })
}
