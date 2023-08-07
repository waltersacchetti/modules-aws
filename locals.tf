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

  output_aws = <<EOT
AWS Information:
        ╠ Profile: ${var.aws.profile}
        ╠ Region: ${var.translation_regions[var.aws.region]}
        ╠ Environment: ${var.translation_environments[element(split("-", var.aws.profile), 1)]}
        ╚ Owner: ${var.aws.owner}
EOT

  output_vpc = length(module.vpc) == 0 ? "No VPC deployed\n" : <<EOT
VPC Information:
${join("\n", [
  for vpc_key, vpc_value in module.vpc : (
    "→ (${vpc_key})${vpc_value.name}:\n\t╠ ID: ${vpc_value.vpc_id}\n\t╠ Public Subnets:\n\t║\t→  ${join("\n\t║\t→  ", try(vpc_value.public_subnets, []))}\n\t╠ Private Subnets:\n\t║\t→  ${join("\n\t║\t→  ", try(vpc_value.private_subnets, []))}\n\t╠ Database Subnets:\n\t║\t→  ${join("\n\t║\t→  ", try(vpc_value.database_subnets, []))}\n\t╚ Elasticache Subnets:\n\t\t→  ${join("\n\t\t→  ", try(vpc_value.elasticache_subnets, []))}"
  )
])}
EOT

output_eks = length(module.eks) == 0 ? "No EKS clusters deployed\n" : <<EOT
EKS Information:
${join("\n", [
for eks_key, eks_value in module.eks : (
  "→ (${eks_key})${eks_value.cluster_name}:\n\t╚ oidc_provider_arn: None"
)
])}
EOT
# output_eks = ""




output_rds = length(module.rds) == 0 ? "No RDS clusters deployed\n" : <<EOT
RDS Information:
${join("\n", [
for key, value in module.rds : (
  "→ (${key})${value.db_instance_identifier}:\n\t╠ Endpoint: ${value.db_instance_endpoint}\n\t╠ Port: ${value.db_instance_port}\n\t╠ Engine: ${value.db_instance_engine}\n\t╠ Version: ${value.db_instance_engine_version_actual}\n\t╠ Username: ${value.db_instance_username}\n\t╚ Password: ${var.aws.resources.rds[key].password == null || var.aws.resources.rds[key].password == "" ? random_password.rds[key].result : var.aws.resources.rds[key].password}"
)
])}
EOT




output_mq = length(aws_mq_broker.this) == 0 ? "No MQ clusters deployed\n" : <<EOT
MQ Information:
${join("\n", [
for key, value in aws_mq_broker.this :
(
  "→ (${key})${value.broker_name}:\n\t╠ Console: ${value.instances[0].console_url}\n\t╠ Endpoints:\n\t║\t→ ${join("\n\t║\t→ ", value.instances[0].endpoints)}\n\t╠ Engine: ${value.engine_type}\n\t╠ Version: ${value.engine_version}\n\t╠ Username: ${var.aws.resources.mq[key].username}\n\t╚ Password: ${var.aws.resources.mq[key].password == null || var.aws.resources.mq[key].password == "" ? random_password.mq[key].result : var.aws.resources.mq[key].password}"
)
])}
EOT


output_elc_memcache_endpoints = length(aws_elasticache_cluster.this) == 0 ? {} : {
  for key, value in aws_elasticache_cluster.this :
  key => [
    for node in value.cache_nodes :
    "${node.id} -- ${node.address}:${node.port}"
  ]
}

output_elc_memcache = length(aws_elasticache_cluster.this) == 0 ? "No ELC Memcache clusters deployed\n" : <<EOT
ElastiCache Memcache Information:
${join("\n", [
for key, value in aws_elasticache_cluster.this :
(
  "→ (${key})${value.cluster_id}:\n\t╠ Address: ${value.cluster_address}\n\t╠ Nodes:\n\t║\t→ ${join("\n\t║\t→ ", local.output_elc_memcache_endpoints[key])}\n\t╠ Engine: ${value.engine}\n\t╚ Version: ${value.engine_version}"
)
])}
EOT

output_elc_redis = length(aws_elasticache_replication_group.this) == 0 ? "No ELC Redis clusters deployed\n" : <<EOT
ElastiCache Redis Information:
${join("\n", [
for key, value in aws_elasticache_replication_group.this :
(
  "→ (${key})${value.id}:\n\t╠ Members: \n\t║\t→ ${join("\n\t║\t→ ", value.member_clusters)}\n\t╠ Endpoints:\n\t║\t→ Primary: ${value.primary_endpoint_address}:${value.port}\n\t║\t→ Reader: ${value.reader_endpoint_address}:${value.port}\n\t╠ Replicas: ${value.replicas_per_node_group}\n\t╠ Engine: ${value.engine}\n\t╚ Version: ${value.engine_version_actual}"
)
])}
EOT


}
