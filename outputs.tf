output "output" {
  value = local.merge_ouput
  # value = local.eks_config
}


output "extras" {
  value = ""
  # value = "${jsonencode(aws_mq_broker.this["main"])}"
  # value = local.eks_map_role_binding
  # value = "${jsonencode(module.vpc["main"])}"
  # value = "${jsonencode(module.sg_ingress_rules)}"
}