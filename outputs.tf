output "output" {
  value = "The aws profile is: ${var.aws.profile} and the default region is ${lookup(var.translation_map, var.aws.region, "")}\nThe eks network is: ${data.aws_subnet.eks_network}"
  # The value of the VPC are:\n${jsonencode(module.vpc["main"])}"
}
