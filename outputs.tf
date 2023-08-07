output "output" {
  value = "${local.output_aws}\n${local.output_vpc}\n${local.output_rds}\n${local.output_mq}\n${local.output_eks}"
  # \n${local.output_rds}
}


output "extras" {
  value = ""
  # value = "${jsonencode(aws_mq_broker.this["main"])}"
  # value = local.eks_map_role_binding
  # value = "${jsonencode(module.vpc["main"])}"
  # value = "${jsonencode(module.sg_ingress_rules)}"
}
