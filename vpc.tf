module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  for_each = var.aws.resources.vpc
  name =  "${var.aws.region}-${var.aws.profile}-vpc-${each.key}"
  cidr = each.value.cidr
}