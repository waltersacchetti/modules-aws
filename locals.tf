locals {
  common_tags = {
    Environment = var.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    Region      = var.translation_regions[var.aws.region]
    Owner       = var.aws.owner
    Terraform   = "true"
  }

  eks_list_namespaces = flatten([
    for key, value in var.aws.resources.eks : [
      for namespace in value.namespaces : {
        namespace = namespace
        eks       = key
      }
    ]
  ])

  eks_map_namespaces = {
    for namespace in local.eks_list_namespaces : "${namespace.eks}_${namespace.namespace}" => namespace
  }

  eks_list_role_binding = flatten([
    for key, value in var.aws.resources.eks : [
      for role in value.role_binding : {
        namespace   = role.namespace
        clusterrole = role.clusterrole
        username    = role.username
        eks         = key
      }
    ]
  ])

  eks_map_role_binding = {
    for role in local.eks_list_role_binding : "${role.eks}_${role.namespace}_${role.clusterrole}_${role.username}" => role
  }

  eks_list_cluster_role_binding = flatten([
    for key, value in var.aws.resources.eks : [
      for role in value.cluster_role_binding : {
        clusterrole = role.clusterrole
        username    = role.username
        eks         = key
      }
    ]
  ])

  eks_map_cluster_role_binding = {
    for role in local.eks_list_cluster_role_binding : "${role.eks}_${role.clusterrole}_${role.username}" => role
  }

  output_elc_memcache_endpoints = length(aws_elasticache_cluster.this) == 0 ? {} : {
  for key, value in aws_elasticache_cluster.this :
  key =>
    "╠ Nodes:\n\t║\t→ ${join("\n\t║\t→", [
          for node in value.cache_nodes :
            "${node.id} -- ${node.address}:${node.port}"
    ])}"
  }
  output_elc_redis_endpoints = length(aws_elasticache_replication_group.this) == 0 ? {} : {
  for key, value in aws_elasticache_replication_group.this :
  key =>  lookup(value, "primary_endpoint_address", null) == null ? join("\n\t", [
        "╠ Configuration endpoints: ${value.configuration_endpoint_address}",
        "╠ Number cluster cache: ${value.num_cache_clusters}",
        "╠ Number node groups: ${value.num_node_groups}"]) : join("\n\t", [
        "╠ Endpoints:",
        "║\t→ Primary: ${value.primary_endpoint_address}:${value.port}",
        "║\t→ Reader: ${value.reader_endpoint_address}:${value.port}"
        ])
  }

  output = {

    aws = <<EOT
╔═══════════════╗
║AWS Information║
╚═══════════════╝
${join("\n\t", [
  "\t╠ Profile: ${var.aws.profile}",
  "╠ Region: ${var.translation_regions[var.aws.region]}",
  "╠ Environment: ${var.translation_environments[element(split("-", var.aws.profile), 1)]}",
  "╚ Owner: ${var.aws.owner}"
])}

EOT

    vpc = length(module.vpc) == 0 ? "" : <<EOT
╔═══════════════╗
║VPC Information║
╚═══════════════╝
${join("\n", [
  for vpc_key, vpc_value in module.vpc : (
  join("\n\t", [
    "→ (${vpc_key})${vpc_value.name}:",
    "╠ ID: ${vpc_value.vpc_id}",
    "╠ Public Subnets:\n\t║\t→  ${join("\n\t║\t→  ", try(vpc_value.public_subnets, []))}",
    "╠ Private Subnets:\n\t║\t→ ${join("\n\t║\t→  ", try(vpc_value.private_subnets, []))}",
    "╠ Database Subnets:\n\t║\t→ ${join("\n\t║\t→  ", try(vpc_value.database_subnets, []))}",
    "╚ Elasticache Subnets:\n\t\t→  ${join("\n\t\t→  ", try(vpc_value.elasticache_subnets, []))}"
  ])
  )
])}

EOT

    eks = length(module.eks) == 0 ? "" : <<EOT
╔═══════════════╗
║EKS Information║
╚═══════════════╝
${join("\n", [
for eks_key, eks_value in module.eks : (
  join("\n\t", [
    "→ (${eks_key})${eks_value.cluster_name}:",
    "╚ oidc_provider_arn: None"
  ])
)
])}

EOT

    rds = length(module.rds) == 0 ? "" : <<EOT
╔═══════════════╗
║RDS Information║
╚═══════════════╝
${join("\n", [
for key, value in module.rds :
(
  join("\n\t", [
    "→ (${key})${value.db_instance_identifier}:",
    "╠ Endpoint: ${value.db_instance_endpoint}",
    "╠ Port: ${value.db_instance_port}",
    "╠ Engine: ${value.db_instance_engine}",
    "╠ Version: ${value.db_instance_engine_version_actual}",
    "╠ Username: ${value.db_instance_username}",
    "╚ Password: ${var.aws.resources.rds[key].password == null || var.aws.resources.rds[key].password == "" ? random_password.rds[key].result : var.aws.resources.rds[key].password}"
  ])
)
])}

EOT

    mq = length(aws_mq_broker.this) == 0 ? "" : <<EOT
╔══════════════╗
║MQ Information║
╚══════════════╝
${join("\n", [
for key, value in aws_mq_broker.this :
(
  join("\n\t", [
    "→ (${key})${value.broker_name}:",
    "╠ Console: ${value.instances[0].console_url}",
    "╠ Endpoints:",
    "║\t→ ${join("\n\t║\t→ ", value.instances[0].endpoints)}",
    "╠ Engine: ${value.engine_type}",
    "╠ Version: ${value.engine_version}",
    "╠ Username: ${var.aws.resources.mq[key].username}",
    "╚ Password: ${var.aws.resources.mq[key].password == null || var.aws.resources.mq[key].password == "" ? random_password.mq[key].result : var.aws.resources.mq[key].password}"
  ])
)
])}

EOT

    elc_memcache = length(aws_elasticache_cluster.this) == 0 ? "" : <<EOT
╔════════════════════════════════╗
║ElastiCache Memcache Information║
╚════════════════════════════════╝
${join("\n", [
for key, value in aws_elasticache_cluster.this :
(
  join("\n\t", [
    "→ (${key})${value.cluster_id}:",
    "╠ Address: ${value.cluster_address}",
    local.output_elc_memcache_endpoints[key],
    "╠ Engine: ${value.engine}",
    "╚ Version: ${value.engine_version}"
  ])
)
])}

EOT

    elc_redis = length(aws_elasticache_replication_group.this) == 0 ? "" : <<EOT
╔═════════════════════════════╗
║ElastiCache Redis Information║
╚═════════════════════════════╝
${join("\n", [
for key, value in aws_elasticache_replication_group.this :
(
  join("\n\t", [
    "(${key})${value.id}",
    "╠ Clusters members:",
    "║\t→ ${join("\n\t║\t→ ", value.member_clusters)}",
    local.output_elc_redis_endpoints[key],
    "╠ Number replicas per node: ${value.replicas_per_node_group}",
    "╠ Engine: ${value.engine}",
    "╚ Version: ${value.engine_version_actual}"
  ])
)
])}

EOT
  }

  merge_ouput = join("", [ for key, value in local.output: (value) ])

}
