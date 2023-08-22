data "aws_subnets" "eks_network" {
  for_each = var.aws.resources.eks
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}

data "aws_subnets" "asg_network" {
  for_each = var.aws.resources.asg
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}

data "aws_subnets" "mq_network" {
  for_each = var.aws.resources.mq
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}

data "aws_subnets" "vpn_network" {
  for_each = var.aws.resources.vpn
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}

# data "aws_vpc" "sg_vpc" {
#   for_each = var.aws.resources.sg
#   filter {
#     name   = "vpc-id"
#     values = [module.vpc[each.value.vpc].vpc_id]
#   }
# }

# data "aws_eks_cluster_auth" "cluster_auth" {
#   name = lookup(var.aws.resources.eks, "main", null) == null ? "" : "${local.translation_regions[var.aws.region]}-${var.aws.profile}-eks-main"
# }

data "aws_subnets" "lb_network" {
  for_each = var.aws.resources.lb
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}


# Configure with the necessary bucket policy
data "aws_iam_policy_document" "s3" {
  for_each = local.s3_map_policy
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.this[each.value].arn]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${local.translation_regions[var.aws.region]}-${var.aws.profile}-bucket-${each.key}",
    ]
  }
}


data "aws_cloudfront_cache_policy" "managed-cachingdisabled" {
  name = "Managed-CachingDisabled"
  #id -> 4135ea2d-6df8-44a3-9df3-4b5a84be39ad
}

data "aws_cloudfront_origin_request_policy" "managed-allviewer" {
  name = "Managed-AllViewer"
  #id -> 216adef6-5c7f-47e4-b989-5492eafa07d3
}

data "aws_cloudfront_response_headers_policy" "managed-cors-with-preflight" {
  name = "Managed-CORS-With-Preflight"
  #id -> 5cc3b908-e619-4b99-88e5-2cf7f45965bd
}