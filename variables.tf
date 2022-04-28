# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "role_permissions_boundary_arn" {
  description = "ARN of the policy that is used to set the permissions boundary for roles created by this module."
  type        = string
  default     = ""
}

variable "api_contract" {
  description = "An OpenAPI specification that defines the set of routes and integrations to create as part of the HTTP APIs"
  type        = string
}

variable "private_subnet_ids" {
  description = "list of private subnets into which the service can be launched"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}

variable "container_image" {
  description = "Docker image to use for the Fargate task."
  type        = string
}

variable "container_environment" {
  description = "Environment variables for the container."
  type        = map(string)
  default = {
    TEST = "TEST"
  }
}

variable "container_port" {
  description = "Port that the container exposes."
  type        = number
  default     = 0
}

variable "desired_count" {
  description = "The initial number of instances of certificate catering tasks to place and keep running - autoscaling may adjust)"
  type        = number
  default     = 1
}

variable "task_definition_cpu" {
  description = "Amount of CPU to reserve for the certificate catering tasks."
  type        = number
  default     = 256
}

variable "task_definition_memory" {
  description = "The soft limit (in MiB) of memory to reserve for the certificate catering containers."
  type        = number
  default     = 512
}