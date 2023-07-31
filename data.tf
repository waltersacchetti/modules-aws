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