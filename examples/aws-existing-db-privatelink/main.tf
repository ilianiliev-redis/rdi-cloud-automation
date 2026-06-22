terraform {
  required_version = ">= 1.5.7"

  backend "local" {
    path = "producer/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "aws_rds_cluster" "source" {
  count = var.enable_rds_failover_lambda && var.rds_source_type == "db-cluster" && var.rds_identifier != null ? 1 : 0

  cluster_identifier = var.rds_identifier
}

data "aws_db_instance" "source" {
  count = var.enable_rds_failover_lambda && var.rds_source_type == "db-instance" && var.rds_identifier != null ? 1 : 0

  db_instance_identifier = var.rds_identifier
}

locals {
  redis_privatelink_arns = (
    var.redis_privatelink_arn == null ? [] :
    can(tolist(var.redis_privatelink_arn)) ? [for arn in tolist(var.redis_privatelink_arn) : tostring(arn)] :
    [tostring(var.redis_privatelink_arn)]
  )

  redis_secrets_arns = (
    var.redis_secrets_arn == null ? [] :
    can(tolist(var.redis_secrets_arn)) ? [for arn in tolist(var.redis_secrets_arn) : tostring(arn)] :
    [tostring(var.redis_secrets_arn)]
  )

  resolved_db_endpoint = try(coalesce(
    var.db_endpoint,
    try(data.aws_rds_cluster.source[0].endpoint, null),
    try(data.aws_db_instance.source[0].address, null),
  ), null)

  resolved_rds_arn = try(coalesce(
    var.rds_arn,
    try(data.aws_rds_cluster.source[0].arn, null),
  ), null)

  resolved_rds_source_id = try(coalesce(
    var.rds_source_id,
    var.rds_identifier,
    try(data.aws_rds_cluster.source[0].cluster_identifier, null),
  ), null)

  targets    = var.enable_rds_failover_lambda ? {} : var.static_targets
  secret_arn = var.create_secret ? module.secret[0].secret_arn : var.existing_secret_arn
}

resource "aws_security_group" "nlb" {
  name        = "${var.name}-nlb"
  description = "RDI PrivateLink NLB for ${var.name}"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow NLB traffic to source database targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nlb"
  })
}

resource "aws_vpc_security_group_ingress_rule" "db_from_nlb" {
  for_each = var.manage_security_group_rule ? toset(var.db_security_group_ids) : []

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.nlb.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "Allow RDI PrivateLink NLB to reach the source database"

  tags = var.tags
}

module "privatelink" {
  source = "../../modules/aws-privatelink"

  identifier          = var.name
  port                = var.db_port
  vpc_id              = var.vpc_id
  subnets             = var.subnet_ids
  target_type         = var.target_type
  targets             = local.targets
  security_groups     = [aws_security_group.nlb.id]
  allowed_principals  = local.redis_privatelink_arns
  acceptance_required = var.acceptance_required
  internal            = var.nlb_internal
}

module "rds_failover" {
  count = var.enable_rds_failover_lambda ? 1 : 0

  source = "../../modules/aws-rds-lambda"

  identifier             = "${var.name}-targets"
  elb_tg_arn             = module.privatelink.tg_arn
  db_endpoint            = local.resolved_db_endpoint
  rds_arn                = local.resolved_rds_arn
  rds_cluster_identifier = local.resolved_rds_source_id
  source_type            = var.rds_source_type
  db_port                = var.db_port

  depends_on = [module.privatelink]
}

resource "random_id" "secret_suffix" {
  count = var.create_secret ? 1 : 0

  byte_length = 8
}

module "secret" {
  count = var.create_secret ? 1 : 0

  source = "../../modules/aws-secret-manager"

  identifier         = "${var.name}-${random_id.secret_suffix[0].hex}"
  allowed_principals = local.redis_secrets_arns
  username           = var.rdi_username
  password           = var.rdi_password
}
