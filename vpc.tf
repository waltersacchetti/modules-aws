# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"
#   for_each = toset(var.aws.resources.vpc) == "" ? {} : var.aws.resources.vpc
#   name =  "${var.aws.region}-${var.aws.profile}-vpc-${each.key}"
#   cidr = each.value.cidr
# }