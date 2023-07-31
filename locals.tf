locals {
  common_tags = {
    Environment = var.translation_environments[element(split("-", var.aws.profile), 1)]
    ProjectKey  = element(split("-", var.aws.profile), 0)
    Region      = var.translation_regions[var.aws.region]
    Owner       = var.aws.owner
    Terraform   = "true"
  }

  output_aws = <<EOT
AWS Information:
        ╠ Profile: ${var.aws.profile}
        ╠ Region: ${var.translation_regions[var.aws.region]}
        ╚ Owner: ${var.aws.owner}
EOT

  output_vpc = <<EOT
VPC Information:
${join("\n", [
  for vpc_key, vpc_value in module.vpc : (
    "→ (${vpc_key})${vpc_value.name}:\n\t╠ ID: ${vpc_value.vpc_id}\n\t╠ Public Subnets: ${join(", ", try(vpc_value.public_subnets, []))}\n\t╠ Private Subnets: ${join(", ", try(vpc_value.private_subnets, []))}\n\t╠ Database Subnets: ${join(", ", try(vpc_value.database_subnets, []))}\n\t╚ Elasticache Subnets: ${join(", ", try(vpc_value.elasticache_subnets, []))}"
  )
])}
EOT

}