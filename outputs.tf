output "output" {
  value = "The aws profile is: ${var.aws.profile} and the default region is ${var.translation_regions[var.aws.region]}\nThe eks network is: ${jsonencode(data.aws_subnets.eks_network["main"])}"
  # The value of the VPC are:\n${jsonencode(module.vpc["main"])}"
}
