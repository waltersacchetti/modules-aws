locals {
  translation_regions = {
    eu-west-1 = "euw1"
    eu-west-2 = "euw2"
    eu-west-3 = "euw3"
    us-east-1 = "use1"
  }

  translation_environments = {
    dev  = "development"
    prod = "production"
    tst  = "test"
    pre  = "preproduction"
    qa   = "qualityassurance"
  }

  common_tags = merge({
    Environment = lookup(local.translation_environments, element(split("-", var.aws.profile), 1), null) == null ? "custom" : local.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    ProjectName = var.aws.project
    Region      = var.aws.region
    Owner       = var.aws.owner
    Terraform   = "true"
  }, var.aws.tags)
}
