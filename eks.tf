# The module of the EKS cluster does not support to define dynamic providers
module "eks" {
  source   = "terraform-aws-modules/eks/aws"
  version  = "19.7.0"
  for_each = var.aws.resources.eks

  cluster_name    = "${var.aws.region}-${var.aws.profile}-eks-${each.key}"
  cluster_version = each.value.cluster_version

  vpc_id     = module.vpc[each.value.vpc].vpc_id
  subnet_ids = data.aws_subnets.eks_network[each.key].ids

  node_security_group_name              = "${var.aws.region}-${var.aws.profile}-sg-eks-node-${each.key}"
  iam_role_name                         = "${var.aws.region}-${var.aws.profile}-iam-role-eks-${each.key}"
  cluster_security_group_name           = "${var.aws.region}-${var.aws.profile}-sg-eks-cluster-${each.key}"
  cluster_additional_security_group_ids = [module.sg[each.value.sg].security_group_id]
  cluster_encryption_policy_name        = "${var.aws.region}-${var.aws.profile}-eks-encryption-policy-${each.key}"

  cluster_endpoint_public_access  = each.value.public
  cluster_endpoint_private_access = true

  create_aws_auth_configmap = each.key == "main" ? length(each.value.eks_managed_node_groups) == 0 ? true: false : false
  manage_aws_auth_configmap = each.key == "main" ? true : false
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
      most_recent    = true
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
    ami_type                   = "AL2_x86_64"
    iam_role_attach_cni_policy = true
    subnets                    = data.aws_subnets.eks_network[each.key].ids
    tags                       = merge(local.common_tags, each.value.tags)
    instance_type              = "t3.medium"
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
      additional_sg_ids  = concat([module.sg[each.value.sg].security_group_id], value.additional_sg_ids)
      kubelet_extra_args = value.kubelet_extra_args
    }
  }
  tags = merge(local.common_tags, each.value.tags)
}

module "eks_iam_role_alb" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version  = "5.28.0"
  for_each = var.aws.resources.eks

  role_name                              = "${var.aws.region}-${var.aws.profile}-eks-iam-${each.key}"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks[each.key].oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  for_each = var.aws.resources.eks
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.eks_iam_role_alb[each.key].iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  for_each   = var.aws.resources.eks
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
  set {
    name  = "region"
    value = var.aws.region
  }

  set {
    name  = "vpcId"
    value = module.vpc[each.value.vpc].vpc_id
  }

  set {
    name  = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "clusterName"
    value = module.eks[each.key].cluster_name
  }
}

resource "kubernetes_role_binding" "this" {
  for_each = local.eks_map_role_binding
  # En realidad solo puede haber un cluster de EKS pero se prepara para posible futuro
  metadata {
    name      = "${each.value.namespace}-${each.value.clusterrole}-${each.value.username}"
    namespace = each.value.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value.clusterrole
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = each.value.username
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  for_each = local.eks_map_cluster_role_binding
  metadata {
    name = "${each.value.clusterrole}-${each.value.username}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value.clusterrole
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = each.value.username
  }
}


module "eks_blueprints_addons" {
  source   = "aws-ia/eks-blueprints-addons/aws"
  version  = "~> 1.0"
  for_each = var.aws.resources.eks

  cluster_name      = module.eks[each.key].cluster_name
  cluster_endpoint  = module.eks[each.key].cluster_endpoint
  cluster_version   = module.eks[each.key].cluster_version
  oidc_provider_arn = module.eks[each.key].oidc_provider_arn

  # This is required to expose Istio Ingress Gateway
  enable_aws_cloudwatch_metrics = true
  enable_aws_for_fluentbit      = true

  tags = merge(local.common_tags, each.value.tags)
}