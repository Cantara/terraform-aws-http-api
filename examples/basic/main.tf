terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      version = "~> 3.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  name_prefix = "http-api-basic-example"
  cidr_block  = "10.1.0.0/16"
}

module "vpc" {
  source  = "git::https://github.com/Cantara/terraform-aws-vpc.git?ref=100e73c"
  cidr_block = local.cidr_block
  public_subnet_cidrs = [
    "10.1.48.0/20"
  ]
  private_subnet_cidrs = [
    "10.1.0.0/20",
    "10.1.16.0/20",
    "10.1.32.0/20"
  ]
  name_prefix         = local.name_prefix
  create_nat_gateways = true

}

module "template" {
  source      = "../../"
  name_prefix = local.name_prefix

  tags = {
    environment = "dev"
    terraform   = "True"
  }
  api_contract = templatefile("${path.module}/openapi.yaml", {
    service_uri   = module.template.aws_service_discovery_service_arn
    connection_id = module.template.aws_apigatewayv2_vpc_link_id
    }
  )
  container_image    = "public.ecr.aws/c6g2n7e9/hello-world:latest"
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
}
