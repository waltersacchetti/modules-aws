# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Locals                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
locals {

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

  # output_eks_cluster_addons = length(module.eks) == 0 ? {} : {
  #   for key, value in module.eks :
  #   key =>
  #   "╠ Cluster Addons \n\t║ ${join("\n\t║", [
  #   for addon in value.cluster_addons :
  #   " \t→ ${addon.addon_name}"
  #   ])}"
  # }

  output_asg_lb = length(aws_lb.asg) == 0 ? {} : {
    for key, value in aws_lb.asg :
    key => "╚ Load Balancer:\n\t ${join("\n\t", [
      "\t╠ Name: ${value.name}",
      "\t╠ Type: ${value.load_balancer_type}",
      "\t╚ Internal: ${value.internal}"
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
        resource_map = module.asg,
        resource_lb  = local.output_asg_lb
    })

    cloudfront = length(aws_cloudfront_distribution.this) == 0 ? "" : templatefile("${path.module}/templates/output-cloudfront.tftpl",
      {
        resource_map    = aws_cloudfront_distribution.this,
        resource_origin = local.output_cloudfront_origin,
        resource_policy = local.output_cloudfront_policy
    })

    ec2 = length(module.ec2) == 0 ? "" : templatefile("${path.module}/templates/output-ec2.tftpl",
      {
        resource_map = module.ec2
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


# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                            Outputs                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
output "output" {
  value = local.merge_ouput
  # value = local.eks_config
}


output "extras" {
  value = ""
  # value = "${jsonencode(aws_mq_broker.this["main"])}"
  # value = local.eks_map_role_binding
  # value = "${jsonencode(module.vpc["main"])}"
  # value = "${jsonencode(module.sg_ingress_rules)}"
}