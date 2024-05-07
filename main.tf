# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.name_prefix}.ecs.local"
  description = "Private DNS namespace for ECS services."
  vpc         = var.vpc_id
  tags        = var.tags
}

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
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  body                         = var.api_contract
  tags                         = var.tags
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  tags        = var.tags
  stage_variables = {"vpc_link_id": aws_apigatewayv2_vpc_link.main.id}

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 1000
  }
  dynamic "route_settings" {
    for_each = var.route_settings
    content {
      route_key              = route_settings.value["route_key"]
      throttling_burst_limit = route_settings.value["throttling_burst_limit"]
      throttling_rate_limit  = route_settings.value["throttling_rate_limit"]
    }
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.agw.arn
    format          = var.access_log_format
  }
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_api.main.id
  description = var.description

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(var.api_contract),
      jsonencode(aws_apigatewayv2_api.main.id),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "agw" {
  name              = "${var.name_prefix}-agw"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_security_group" "vpc_link" {
  vpc_id      = var.vpc_id
  name        = "${var.name_prefix}-vpc-link-sg"
  description = "API Gateway (v2) VPC Link security group"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc-link-sg"
  })
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name = "${var.name_prefix}-vpc-link"
  security_group_ids = [
  aws_security_group.vpc_link.id]
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
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
  from_port                = var.container_port
  to_port                  = var.container_port
  source_security_group_id = aws_security_group.vpc_link.id
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"
  tags = var.tags
}

module "fargate" {
  source                             = "github.com/Cantara/terraform-aws-ecs-fargate?ref=22c2ab5"
  name_prefix                        = var.name_prefix
  vpc_id                             = var.vpc_id
  private_subnet_ids                 = var.private_subnet_ids
  cluster_id                         = aws_ecs_cluster.cluster.id
  container_health_check             = var.container_health_check
  task_container_image               = var.container_image
  task_container_environment         = var.container_environment
  task_definition_cpu                = var.task_definition_cpu
  task_definition_memory             = var.task_definition_memory
  desired_count                      = var.desired_count
  task_container_port                = var.container_port
  task_container_assign_public_ip    = false
  task_role_permissions_boundary_arn = var.role_permissions_boundary_arn
  service_registry_arn               = aws_service_discovery_service.main.arn
  with_service_discovery_srv_record  = true
  wait_for_steady_state              = true

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  tags = var.tags
}
