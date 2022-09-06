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

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service role."
  value       = module.fargate.task_role_arn
}

output "task_role_name" {
  description = "The name of the service role."
  value       = module.fargate.task_role_name
}

output "task_execution_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the execution service role."
  value       = module.fargate.task_execution_role_arn
}

output "task_execution_role_name" {
  description = "The name of the execution service role."
  value       = module.fargate.task_execution_role_name
}

output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = module.fargate.service_arn
}

output "api_id" {
  description = "The id of the API"
  value       = aws_apigatewayv2_api.main.id
}

output "stage_id" {
  description = "The id of the deployed stage"
  value       = aws_apigatewayv2_stage.main.id
}