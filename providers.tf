terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Reemplaza esto con la versión adecuada del proveedor "random"
    }
  }
}

# Terrafom does not support dynamic providers yet,
# https://github.com/hashicorp/terraform/issues/24476
# provider "kubernetes" {
#   # host                   = lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
#   # cluster_ca_certificate = lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
#   # # token                  = data.aws_eks_cluster_auth.cluster_auth.token

#   # exec {
#   #   api_version = "client.authentication.k8s.io/v1beta1"
#   #   command     = "aws"
#   #   # This requires the awscli to be installed locally where Terraform is executed
#   #   args = ["eks", "get-token", "--cluster-name", lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", var.aws.region, "--profile", var.aws.profile]
#   # }
#   # config_path    = "data/${terraform.workspace}/eks/main/admin.kubeconfig"

#   host                   = local.eks_config.host != null ? local.eks_config.host : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
#   cluster_ca_certificate = local.eks_config.cluster_ca_certificate != null ? local.eks_config.cluster_ca_certificate : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
#   exec {
#     api_version = local.eks_config.exec_api_version != null ? local.eks_config.exec_api_version : "client.authentication.k8s.io/v1beta1"
#     command     = local.eks_config.exec_command != null ? local.eks_config.exec_command : "aws"
#     args        = local.eks_config.args != null ? local.eks_config.args : ["eks", "get-token", "--cluster-name", lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", var.aws.region, "--profile", var.aws.profile]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = local.eks_config.host != null ? local.eks_config.host : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
#     cluster_ca_certificate = local.eks_config.cluster_ca_certificate != null ? local.eks_config.cluster_ca_certificate : lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
#     exec {
#       api_version = local.eks_config.exec_api_version != null ? local.eks_config.exec_api_version : "client.authentication.k8s.io/v1beta1"
#       command     = local.eks_config.exec_command != null ? local.eks_config.exec_command : "aws"
#       args        = local.eks_config.args != null ? local.eks_config.args : ["eks", "get-token", "--cluster-name", lookup(var.aws.resources, "eks", null) == null ? "" : lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", var.aws.region, "--profile", var.aws.profile]
#     }
#     # config_path    = "data/${terraform.workspace}/eks/main/admin.kubeconfig"
#   }
# }