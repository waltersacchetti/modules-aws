# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
# ╔═════════════════════════════╗
# ║ Create ELC Memcache         ║
# ╚═════════════════════════════╝
resource "aws_elasticache_cluster" "this" {
  for_each   = { for k, v in var.aws.resources.elc : k => v if v.engine == "memcached" }
  cluster_id = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-elc-${each.key}"

  engine               = each.value.engine
  engine_version       = each.value.engine_version
  port                 = 11211
  parameter_group_name = each.value.parameter_group_name

  node_type       = each.value.node_type
  num_cache_nodes = each.value.num_cache_nodes

  subnet_group_name  = module.vpc[each.value.vpc].elasticache_subnet_group
  security_group_ids = [module.sg[each.value.sg].security_group_id]
  az_mode            = each.value.num_cache_nodes > 1 ? "cross-az" : "single-az"
  tags               = merge(local.common_tags, each.value.tags)
}


# ╔═════════════════════════════╗
# ║ Create ELC Redis            ║
# ╚═════════════════════════════╝

resource "aws_elasticache_replication_group" "this" {
  for_each             = { for k, v in var.aws.resources.elc : k => v if v.engine == "redis" }
  replication_group_id = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-elc-${each.key}"
  description          = "Redis Replication Group for ${each.key}"

  engine               = each.value.engine
  engine_version       = each.value.engine_version
  port                 = 6379
  parameter_group_name = each.value.parameter_group_name

  node_type          = each.value.node_type
  subnet_group_name  = module.vpc[each.value.vpc].elasticache_subnet_group
  security_group_ids = [module.sg[each.value.sg].security_group_id]
  multi_az_enabled   = each.value.num_cache_clusters > 1 ? true : each.value.num_node_groups > 1 ? true : false

  automatic_failover_enabled = each.value.num_cache_clusters > 1 ? true : each.value.num_node_groups > 1 ? true : false

  num_cache_clusters = each.value.num_cache_clusters == 0 ? null : each.value.num_cache_clusters == "" ? null : each.value.num_cache_clusters

  num_node_groups         = each.value.num_node_groups == 0 ? null : each.value.num_node_groups == "" ? null : each.value.num_node_groups
  replicas_per_node_group = each.value.replicas_per_node_group == 0 ? null : each.value.replicas_per_node_group == "" ? null : each.value.replicas_per_node_group

  tags = merge(local.common_tags, each.value.tags)
}