output "output" {
  value = "${local.output_aws}\n${local.output_vpc}\n${local.output_rds}\n${local.output_eks}"
  # \n${local.output_rds}
}


output "extras" {
  # value = ""
  value = "${nonsensitive(local.output_rds)}"
}
