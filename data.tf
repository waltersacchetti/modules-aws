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

# data "aws_vpc" "sg_vpc" {
#   for_each = var.aws.resources.sg
#   filter {
#     name   = "vpc-id"
#     values = [module.vpc[each.value.vpc].vpc_id]
#   }
# }