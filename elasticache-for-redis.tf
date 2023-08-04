resource "aws_elasticache_cluster" "elastic-cache-for-redis"{
  for_each             = var.aws.resources.elasticache-redis
  cluster_id           = each.value.cluster_id
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  node_type            = each.value.node_type
  num_cache_nodes      = each.value.num_cache_nodes
  parameter_group_name = each.value.parameter_group_name
  port                 = each.value.port
  subnet_group_name    = module.vpc[each.value.vpc].elasticache_subnet_group
  security_group_ids   = [module.sg[each.value.security_group].security_group_id]
  tags                 = merge(local.common_tags, each.value.tags)
}