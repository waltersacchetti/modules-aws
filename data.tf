data "aws_subnets" "eks_network" {
  for_each = var.aws.resources.eks
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${var.aws.region}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
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
    values = [for key in each.value.vpc_zone_identifier : join(",", ["${var.aws.region}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
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
    values = [for key in each.value.subnets : join(",", ["${var.aws.region}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
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
#   name = lookup(var.aws.resources.eks, "main", null) == null ? "" : "${var.aws.region}-${var.aws.profile}-eks-main"
# }

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
      "arn:aws:s3:::${var.aws.region}-${var.aws.profile}-bucket-${each.key}",
    ]
  }
}