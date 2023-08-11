provider "aws" {
  region  = local.translation_regions[var.aws.region]
  profile = var.aws.profile
}

# Terrafom does not support dynamic providers yet,
# https://github.com/hashicorp/terraform/issues/24476
provider "kubernetes" {
  host                   = lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
  cluster_ca_certificate = lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
  # token                  = data.aws_eks_cluster_auth.cluster_auth.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", local.translation_regions[var.aws.region], "--profile", var.aws.profile]
  }
  # config_path    = "/tmp/test"
}

provider "helm" {
  kubernetes {
    host                   = lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_endpoint
    cluster_ca_certificate = lookup(var.aws.resources.eks, "main", null) == null ? "" : base64decode(module.eks["main"].cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", lookup(var.aws.resources.eks, "main", null) == null ? "" : module.eks["main"].cluster_name, "--region", local.translation_regions[var.aws.region], "--profile", var.aws.profile]
    }
  }
}

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Reemplaza esto con la versión adecuada del proveedor "random"
    }
  }
}
