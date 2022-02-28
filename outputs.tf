# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "name_prefix" {
  value = var.name_prefix
}

output "tags" {
  value = var.tags
}

output "aws_service_discovery_service_arn" {
  value = aws_service_discovery_service.main.arn
}

output "aws_apigatewayv2_vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.main.id
}
