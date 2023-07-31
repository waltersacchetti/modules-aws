output "output" {
  value = "${local.output_aws}\n${local.output_vpc}\n${local.output_eks}"
}
