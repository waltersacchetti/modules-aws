module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  for_each        = var.aws.resources.eks
  cluster_name    = "${var.aws.region}-${var.aws.profile}-eks-${each.key}"
  cluster_version = each.value.cluster_version
  vpc_id          = module.vpc[each.value.vpc].vpc_id
  subnet_ids      = data.aws_subnets.eks_network[each.key].ids
  tags            = merge(local.common_tags, each.value.tags)
}