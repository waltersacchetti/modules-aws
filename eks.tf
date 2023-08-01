module "eks" {
  source   = "terraform-aws-modules/eks/aws"
  for_each = var.aws.resources.eks

  cluster_name    = "${var.aws.region}-${var.aws.profile}-eks-${each.key}"
  cluster_version = each.value.cluster_version

  vpc_id                                = module.vpc[each.value.vpc].vpc_id
  subnet_ids                            = data.aws_subnets.eks_network[each.key].ids
  cluster_security_group_name           = "${var.aws.region}-${var.aws.profile}-sg-eks-cluster-${each.key}"
  cluster_additional_security_group_ids = [module.sg[each.value.sg].security_group_id]

  cluster_endpoint_public_access  = each.value.public == true ? true : false
  cluster_endpoint_private_access = each.value.public == true ? false : true

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    for role in each.value.aws_auth_roles : {
      rolearn  = role.arn
      username = role.username
      groups   = role.groups
    }
  ]

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cluster_addons = {
    aws-ebs-csi-driver = {}
    aws-efs-csi-driver = {}
    coredns            = {}
    kube-proxy         = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference https://aws.github.io/aws-eks-best-practices/reliability/docs/networkmanagement/#cni-custom-networking
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "false"
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"

          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  eks_managed_node_group_defaults = {
    ami_type      = "AL2_x86_64"
    subnets       = data.aws_subnets.eks_network[each.key].ids
    tags          = merge(local.common_tags, each.value.tags)
    instance_type = "t3.medium"
  }

  eks_managed_node_groups = {
    for name, value in each.value.eks_managed_node_groups : name => {
      name               = "${var.aws.region}-emng-${each.key}-${name}"
      ami_type           = value.ami_type
      desired_capacity   = value.desired_capacity
      instance_type      = value.instance_type
      min_size           = value.min_size
      max_size           = value.max_size
      desired_capacity   = value.desired_capacity
      disk_size          = value.disk_size
      additional_sg_ids  = concat(value.additional_sg_ids, [module.sg[each.value.sg].security_group_id])
      kubelet_extra_args = value.kubelet_extra_args
    }
  }
  tags = merge(local.common_tags, each.value.tags)
}