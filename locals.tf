locals {
  translation_regions = {
    eu-west-1 = "euw1"
    eu-west-2 = "euw2"
    eu-west-3 = "euw3"
    us-east-1 = "use1"
  }

  translation_environments = {
    dev  = "development"
    prod = "production"
    tst  = "test"
    pre  = "preproduction"
    qa   = "qualityassurance"
  }

  translation_rds_ports = {
    aurora   = 3306
    mysql    = 3306
    postgres = 5432
  }

  common_tags = {
    Environment = local.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    Region      = var.aws.region
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
      for role in value.role_binding : [
        for namespace in role.namespaces : {
          namespace   = namespace
          clusterrole = role.clusterrole
          username    = role.username
          eks         = key
  }]]])

  eks_map_role_binding = {
    for role in local.eks_list_role_binding : "${role.eks}_${role.namespace}_${role.clusterrole}_${role.username}" => role
  }

  eks_list_cluster_role_binding = flatten([
    for key, value in var.aws.resources.eks : [
      for role in value.cluster_role_binding : {
        clusterrole = role.clusterrole
        username    = role.username
        eks         = key
  }]])

  eks_map_cluster_role_binding = {
    for role in local.eks_list_cluster_role_binding : "${role.eks}_${role.clusterrole}_${role.username}" => role
  }

  # output_eks_cluster_addons = length(module.eks) == 0 ? {} : {
  #   for key, value in module.eks :
  #   key =>
  #   "╠ Cluster Addons \n\t║ ${join("\n\t║", [
  #   for addon in value.cluster_addons :
  #   " \t→ ${addon.addon_name}"
  #   ])}"
  # }

  output_eks_nodegroups = length(module.eks) == 0 ? {} : {
    for key, value in module.eks :
    key =>
    "╠ Node groups: \n\t║ ${join("\n\t║", [
      for nodeg in value.eks_managed_node_groups :
      " \t→ ${nodeg.node_group_id}"
    ])}"
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
    key => lookup(value, "primary_endpoint_address", null) == null ? join("\n\t", [
      "╠ Configuration endpoints: ${value.configuration_endpoint_address}",
      "╠ Number cluster cache: ${value.num_cache_clusters}",
      "╠ Number node groups: ${value.num_node_groups}"]) : join("\n\t", [
      "╠ Endpoints:",
      "║\t→ Primary: ${value.primary_endpoint_address}:${value.port}",
      "║\t→ Reader: ${value.reader_endpoint_address}:${value.port}"
    ])
  }

  s3_list_policy = flatten([
    for key, value in var.aws.resources.s3 : [
      value.iam != "" ? {
        bucket = key
        policy = value.iam
      } : null
    ]
  ])

  s3_map_policy = {
    for policy in local.s3_list_policy : policy.bucket => policy.policy
  }

  output_cloudfront_origin = length(aws_cloudfront_distribution.this) == 0 ? {} : {
    for key, value in aws_cloudfront_distribution.this :
    key =>
    "╠ Cloudfront origin \n\t║\t║ ${join("\n\t║\t→", [
      for origin in value.origin :
      "Domain Name: ${origin.domain_name}\n\t║\t╚ Id: ${origin.origin_id} "
    ])}"
  }

  output_cloudfront_policy = length(aws_cloudfront_cache_policy.this) == 0 ? {} : {
    for key, value in aws_cloudfront_cache_policy.this :
    key =>
    "╚ Cloudfront Custom Cache Policies \n\t\t║ ${join("\n\t\t║", [
      for policy in aws_cloudfront_cache_policy.this :
      " Id: ${policy.id}\n\t\t╚ Name: ${policy.name}"
    ])}"
  }

  output = {
    # Let AWS the first output
    a_aws = templatefile("${path.module}/templates/aws.tftpl",
      {
        profile     = var.aws.profile,
        region      = var.aws.region,
        environment = local.translation_environments[element(split("-", var.aws.profile), 1)],
        owner       = var.aws.owner
    })

    a_vpc = length(module.vpc) == 0 ? "" : templatefile("${path.module}/templates/vpc.tftpl",
      {
        resource_map = module.vpc
    })

    asg = length(module.asg) == 0 ? "" : templatefile("${path.module}/templates/asg.tftpl",
      {
        resource_map = module.asg
    })

    cloudfront = length(aws_cloudfront_distribution.this) == 0 ? "" : templatefile("${path.module}/templates/cloudfront.tftpl",
      {
        resource_map    = aws_cloudfront_distribution.this,
        resource_origin = local.output_cloudfront_origin,
        resource_policy = local.output_cloudfront_policy
    })

    eks = length(module.eks) == 0 ? "" : templatefile("${path.module}/templates/eks.tftpl",
      {
        resource_map        = module.eks,
        resource_node_group = local.output_eks_nodegroups
    })

    elc_memcache = length(aws_elasticache_cluster.this) == 0 ? "" : templatefile("${path.module}/templates/elc_memcache.tftpl",
      {
        resource_map       = aws_elasticache_cluster.this,
        resource_endpoints = local.output_elc_memcache_endpoints
    })

    elc_redis = length(aws_elasticache_replication_group.this) == 0 ? "" : templatefile("${path.module}/templates/elc_redis.tftpl",
      {
        resource_map       = aws_elasticache_replication_group.this,
        resource_endpoints = local.output_elc_redis_endpoints
    })

    iam = length(aws_iam_role.this) == 0 ? "" : templatefile("${path.module}/templates/iam.tftpl",
      {
        resource_map = aws_iam_role.this
    })

    kinesis = length(aws_kinesis_video_stream.this) == 0 ? "" : templatefile("${path.module}/templates/kinesis.tftpl",
      {
        resource_map = aws_kinesis_video_stream.this
    })

    lb = length(aws_lb.this) == 0 ? "" : templatefile("${path.module}/templates/lb.tftpl",
      {
        resource_map    = aws_lb.this,
        resource_config = var.aws.resources.lb,
    })

    mq = length(aws_mq_broker.this) == 0 ? "" : templatefile("${path.module}/templates/mq.tftpl",
      {
        resource_map    = aws_mq_broker.this,
        resource_config = var.aws.resources.mq,
        password        = random_password.mq
    })

    rds = length(module.rds) == 0 ? "" : templatefile("${path.module}/templates/rds.tftpl",
      {
        resource_map    = module.rds,
        resource_config = var.aws.resources.rds,
        password        = random_password.rds
    })

    s3 = length(module.s3) == 0 ? "" : templatefile("${path.module}/templates/s3.tftpl",
      {
        resource_map = module.s3
    })

    waf = length(aws_wafv2_web_acl.this) == 0 ? "" : templatefile("${path.module}/templates/waf.tftpl",
      {
        resource_map = aws_wafv2_web_acl.this
    })
  }

  merge_ouput = join("", [for key, value in local.output : (value)])

}
