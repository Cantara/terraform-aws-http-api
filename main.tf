# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

resource "aws_service_discovery_service" "main" {
  name = "${var.name_prefix}-service"
  tags = var.tags

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.main.id
    routing_policy = "MULTIVALUE"

    dns_records {
      type = "SRV"
      ttl  = 10
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_apigatewayv2_api" "main" {
  name                         = var.name_prefix
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = false
  body                         = var.api_contract
  tags                         = var.tags
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
  tags        = var.tags

  default_route_settings {
    detailed_metrics_enabled = true
    logging_level            = "INFO"
    throttling_burst_limit   = 100
    throttling_rate_limit    = 1000
    # TODO: Figure out a good rate/burst limit.
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.agw.arn
    format          = <<EOT
{"requestId":"$context.requestId", "ip":"$context.identity.sourceIp", "requestTime":"$context.requestTime", "httpMethod":"$context.httpMethod", "resourcePath":"$context.resourcePath", "status":"$context.status", "protocol":"$context.protocol", "responseLength":"$context.responseLength" }
EOT
  }
}

resource "aws_cloudwatch_log_group" "agw" {
  name              = "${var.name_prefix}-agw"
  retention_in_days = 7
  tags              = var.tags
}


resource "aws_apigatewayv2_vpc_link" "main" {
  name = "${var.name_prefix}-vpc-link"
  security_group_ids = [
  aws_security_group.vpc_link.id]
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}


resource "aws_security_group" "vpc_link" {
  vpc_id      = var.vpc_id
  name        = "${var.name_prefix}-vpc-link-sg"
  description = "API Gateway (v2) VPC Link security group"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-link-sg"
  })
}

resource "aws_security_group_rule" "link_egress_all" {
  security_group_id = aws_security_group.vpc_link.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks = [
  "0.0.0.0/0"]
  ipv6_cidr_blocks = [
  "::/0"]
}

resource "aws_security_group_rule" "link_ingress_task" {
  security_group_id        = module.fargate.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8000
  to_port                  = 8000
  source_security_group_id = aws_security_group.vpc_link.id
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"
}

module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "5.2.0"

  name_prefix                        = var.name_prefix
  vpc_id                             = var.vpc_id
  private_subnet_ids                 = var.private_subnet_ids
  cluster_id                         = aws_ecs_cluster.cluster.id
  task_container_image               = var.container_image
  task_container_environment         = var.container_environment
  task_container_port                = 8000
  task_container_assign_public_ip    = false
  task_role_permissions_boundary_arn = var.role_permissions_boundary_arn
  service_registry_arn               = aws_service_discovery_service.main.arn
  with_service_discovery_srv_record  = true
  wait_for_steady_state              = true

  health_check = {
    port = "traffic-port"
    path = "/actuator/health"
  }

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  tags = var.tags
}

//resource "aws_iam_role" "api-gw-lambda_invoke" {
//  name                 = "${var.name_prefix}-api-gw-lambda-invoke"
//  description          = "Role for the API Gateway that can invoke lambdas"
//  assume_role_policy   = data.aws_iam_policy_document.lambda_invoke_assume.json
//  permissions_boundary = var.role_permissions_boundary_arn
//}

//resource "aws_iam_role_policy" "lambda_to_api-gw-lambda_invoke" {
//  role   = aws_iam_role.api-gw-lambda_invoke.id
//  policy = data.aws_iam_policy_document.lambda_for_api-gw-lambda_invoke.json
//}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.name_prefix}.ecs.local"
  description = "Private DNS namespace for ECS services."
  vpc         = var.vpc_id
  tags        = var.tags
}