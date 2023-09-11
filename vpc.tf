# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Locals                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
locals {
  vpc_list_private_nat_gateway = flatten([
    for key, value in var.aws.resources.vpc : [
      for subnet in value.private_nat_gateway : {
        vpc    = key
        subnet = subnet
      }
    ]
  ])
  vpc_map_private_nat_gateway = {
    for subnet in local.vpc_list_private_nat_gateway : "${subnet.vpc}_${subnet.subnet}" => subnet
  }
  vpc_list_aws_route = flatten([
    for key, value in var.aws.resources.vpc : [
      for route_key, route_value in value.aws_route : [
        for route in route_value : { 
            vpc                 = key
            subnet              = route_key
            cidr_block          = route.cidr_block
            private_nat_gateway = route.private_nat_gateway
        }
      ]
    ]
  ])
  vpc_map_aws_route = {
    for route in local.vpc_list_aws_route : "${route.vpc}_${route.subnet}_${route.cidr_block}" => route
  }
}

# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Data                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
data "aws_subnets" "vpc_private_nat_gateway" {
  for_each = local.vpc_map_private_nat_gateway
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${each.value.subnet}"]
  }
}

data "aws_subnets" "aws_route" {
  for_each = local.vpc_map_aws_route
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${each.value.subnet}"]
  }
}

data "aws_route_table" "aws_route" {
  for_each  = local.vpc_map_aws_route
  vpc_id    = module.vpc[each.value.vpc].vpc_id
  subnet_id = data.aws_subnets.aws_route[each.key].ids[0]
}

# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "5.1.1"
  for_each              = var.aws.resources.vpc
  name                  = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}"
  azs                   = each.value.azs
  cidr                  = each.value.cidr
  secondary_cidr_blocks = each.value.secondary_cidr_blocks
  tags                  = merge(local.common_tags, each.value.tags)

  enable_nat_gateway   = each.value.enable_nat_gateway
  single_nat_gateway   = var.aws.resources.alternat.vpc == each.key ? false : each.value.single_nat_gateway
  enable_vpn_gateway   = each.value.enable_vpn_gateway
  enable_dns_hostnames = each.value.enable_dns_hostnames
  enable_dns_support   = each.value.enable_dns_support

  ## Alternat Configuration
  manage_default_network_acl    = var.aws.resources.alternat.vpc == each.key ? true : false
  manage_default_route_table    = var.aws.resources.alternat.vpc == each.key ? true : false
  manage_default_security_group = var.aws.resources.alternat.vpc == each.key ? true : false

  public_subnets      = [for value in each.value.public_subnets : join(",", [value])]
  public_subnet_names = [for key, _ in each.value.public_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-public-${key}"])]

  private_subnets      = [for value in each.value.private_subnets : join(",", [value])]
  private_subnet_names = [for key, _ in each.value.private_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]

  create_database_subnet_group           = length(each.value.database_subnets) == 0 ? false : each.value.create_database_subnet_group
  create_database_subnet_route_table     = length(each.value.database_subnets) == 0 ? false : each.value.create_database_subnet_route_table == null ? each.value.create_database_subnet_group : each.value.create_database_subnet_route_table
  create_database_internet_gateway_route = each.value.create_database_internet_gateway_route
  database_subnets                       = [for value in each.value.database_subnets : join(",", [value])]
  database_subnet_names                  = [for key, _ in each.value.database_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]

  create_elasticache_subnet_group       = length(each.value.elasticache_subnets) == 0 ? false : each.value.create_elasticache_subnet_group
  create_elasticache_subnet_route_table = length(each.value.elasticache_subnets) == 0 ? false : each.value.create_elasticache_subnet_route_table == null ? each.value.create_elasticache_subnet_group : each.value.create_elasticache_subnet_route_table
  elasticache_subnets                   = [for value in each.value.elasticache_subnets : join(",", [value])]
  elasticache_subnet_names              = [for key, _ in each.value.elasticache_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]
}

resource "aws_nat_gateway" "this" {
  for_each          = local.vpc_map_private_nat_gateway
  connectivity_type = "private"
  subnet_id         = data.aws_subnets.vpc_private_nat_gateway[each.key].ids[0]
  tags                       = merge(local.common_tags, {
    Name = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${each.value.subnet}-nat-gateway"
  })
}

resource "aws_route" "this" {
  for_each  = local.vpc_map_aws_route
  route_table_id            = data.aws_route_table.aws_route[each.key].id
  destination_cidr_block    = each.value.cidr_block
  nat_gateway_id            = each.value.private_nat_gateway == null ? null :  aws_nat_gateway.this["${each.value.vpc}_${each.value.subnet}"].id
}
