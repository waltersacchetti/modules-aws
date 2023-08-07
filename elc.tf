resource "aws_elasticache_cluster" "this"{
  for_each             = var.aws.resources.elc
  cluster_id           = "${var.aws.region}-${var.aws.profile}-elc-${each.key}"
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