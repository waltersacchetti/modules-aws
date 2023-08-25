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

  common_tags = merge({
    Environment = lookup(local.translation_environments, element(split("-", var.aws.profile), 1), null) == null ? "custom" : local.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    ProjectName = var.aws.project
    Region      = var.aws.region
    Owner       = var.aws.owner
    Terraform   = "true"
  }, var.aws.tags)

  eks_managed_node_groups = {
    for nodegroup in flatten([
      for key, value in var.aws.resources.eks : [
        for mng_key, mng_value in value.eks_managed_node_groups : length(mng_value.subnets) > 0 ? {
          eks     = key
          mng     = mng_key
          subnets = mng_value.subnets
          vpc     = value.vpc
          } : {
          eks     = key
          mng     = mng_key
          subnets = value.subnets
          vpc     = value.vpc
        }
      ]
      ]) : "${nodegroup.eks}_${nodegroup.mng}" => {
      subnets = nodegroup.subnets
      vpc     = nodegroup.vpc
    }
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

  eks_config_yaml = fileexists("data/${terraform.workspace}/eks/main/admin.kubeconfig") ? yamldecode(file("data/${terraform.workspace}/eks/main/admin.kubeconfig")) : null

  eks_config = {
    host                   = local.eks_config_yaml != null ? local.eks_config_yaml.clusters[0].cluster.server : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
    cluster_ca_certificate = local.eks_config_yaml != null ? base64decode(local.eks_config_yaml.clusters[0].cluster["certificate-authority-data"]) : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
    exec_api_version       = "client.authentication.k8s.io/v1beta1"
    exec_command           = "aws"
    args                   = local.eks_config_yaml != null ? local.eks_config_yaml.users[0].user.exec.args : ["eks", "get-token", "--cluster-name", lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", var.aws.region, "--profile", var.aws.profile]
  }

  rds_list_postgres_databases = flatten([
    for key, value in var.aws.resources.rds : [
      value.engine == "postgres" && length(value.databases) > 0 ? [
        for database in value.databases : {
          rds  = key
          name = database
        }
      ] : null
    ]
  ])

  rds_map_postgres_databases = {
    for database in local.rds_list_postgres_databases : "${database.rds}_${database.name}" => database
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
    a_aws = templatefile("${path.module}/templates/output-aws.tftpl",
      {
        profile     = var.aws.profile,
        region      = var.aws.region,
        environment = lookup(local.translation_environments, element(split("-", var.aws.profile), 1), null) == null ? "custom" : local.translation_environments[element(split("-", var.aws.profile), 1)],
        owner       = var.aws.owner
    })

    a_vpc = length(module.vpc) == 0 ? "" : templatefile("${path.module}/templates/output-vpc.tftpl",
      {
        resource_map = module.vpc
    })

    asg = length(module.asg) == 0 ? "" : templatefile("${path.module}/templates/output-asg.tftpl",
      {
        resource_map = module.asg
    })

    cloudfront = length(aws_cloudfront_distribution.this) == 0 ? "" : templatefile("${path.module}/templates/output-cloudfront.tftpl",
      {
        resource_map    = aws_cloudfront_distribution.this,
        resource_origin = local.output_cloudfront_origin,
        resource_policy = local.output_cloudfront_policy
    })

    eks = length(module.eks) == 0 ? "" : templatefile("${path.module}/templates/output-eks.tftpl",
      {
        resource_map        = module.eks,
        resource_node_group = local.output_eks_nodegroups
    })

    elc_memcache = length(aws_elasticache_cluster.this) == 0 ? "" : templatefile("${path.module}/templates/output-elc_memcache.tftpl",
      {
        resource_map       = aws_elasticache_cluster.this,
        resource_endpoints = local.output_elc_memcache_endpoints
    })

    elc_redis = length(aws_elasticache_replication_group.this) == 0 ? "" : templatefile("${path.module}/templates/output-elc_redis.tftpl",
      {
        resource_map       = aws_elasticache_replication_group.this,
        resource_endpoints = local.output_elc_redis_endpoints
    })

    iam = length(aws_iam_role.this) == 0 ? "" : templatefile("${path.module}/templates/output-iam.tftpl",
      {
        resource_map = aws_iam_role.this
    })

    kinesis = length(aws_kinesis_video_stream.this) == 0 ? "" : templatefile("${path.module}/templates/output-kinesis.tftpl",
      {
        resource_map = aws_kinesis_video_stream.this
    })

    lb = length(aws_lb.this) == 0 ? "" : templatefile("${path.module}/templates/output-lb.tftpl",
      {
        resource_map    = aws_lb.this,
        resource_config = var.aws.resources.lb,
    })

    mq = length(aws_mq_broker.this) == 0 ? "" : templatefile("${path.module}/templates/output-mq.tftpl",
      {
        resource_map    = aws_mq_broker.this,
        resource_config = var.aws.resources.mq,
        password        = random_password.mq
    })

    rds = length(module.rds) == 0 ? "" : templatefile("${path.module}/templates/output-rds.tftpl",
      {
        resource_map    = module.rds,
        resource_config = var.aws.resources.rds,
        password        = random_password.rds
    })

    s3 = length(module.s3) == 0 ? "" : templatefile("${path.module}/templates/output-s3.tftpl",
      {
        resource_map = module.s3
    })

    waf = length(aws_wafv2_web_acl.this) == 0 ? "" : templatefile("${path.module}/templates/output-waf.tftpl",
      {
        resource_map = aws_wafv2_web_acl.this
    })
  }

  merge_ouput = join("", [for key, value in local.output : (value)])

}
