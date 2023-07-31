output "output" {
  value = "The aws profile is: ${var.aws.profile} and the default region is ${lookup(var.translation_map, var.aws.region, "")}"
}
