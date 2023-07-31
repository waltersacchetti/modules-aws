module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  for_each = toset(var.aws.resources.vpc) == "" ? {} : var.aws.resources.vpc
  name = each.value.name
  cidr = each.value.cidr
}