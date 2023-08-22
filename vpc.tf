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
  single_nat_gateway   = each.value.single_nat_gateway
  enable_vpn_gateway   = each.value.enable_vpn_gateway
  enable_dns_hostnames = each.value.enable_dns_hostnames
  enable_dns_support   = each.value.enable_dns_support

  public_subnets      = [for value in each.value.public_subnets : join(",", [value])]
  public_subnet_names = [for key, _ in each.value.public_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-public-${key}"])]

  private_subnets      = [for value in each.value.private_subnets : join(",", [value])]
  private_subnet_names = [for key, _ in each.value.private_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]

  create_database_subnet_group           = length(each.value.database_subnets) > 0 ? each.value.create_database_subnet_group : false
  create_database_subnet_route_table     = each.value.create_database_subnet_route_table
  create_database_internet_gateway_route = each.value.create_database_internet_gateway_route
  database_subnets                       = [for value in each.value.database_subnets : join(",", [value])]
  database_subnet_names                  = [for key, _ in each.value.database_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]

  create_elasticache_subnet_group       = length(each.value.elasticache_subnets) > 0 ? each.value.create_elasticache_subnet_group : false
  create_elasticache_subnet_route_table = each.value.create_elasticache_subnet_route_table
  elasticache_subnets                   = [for value in each.value.elasticache_subnets : join(",", [value])]
  elasticache_subnet_names              = [for key, _ in each.value.elasticache_subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.key}-${key}"])]


}