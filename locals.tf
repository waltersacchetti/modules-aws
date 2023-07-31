locals {
  common_tags = {
    Environment = var.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    Region      = var.translation_regions[var.aws.region]
    Owner       = var.aws.owner
    Terraform   = "true"
  }
}