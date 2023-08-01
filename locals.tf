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
        ╠ Environment: ${var.translation_environments[element(split("-", var.aws.profile), 1)]}
        ╚ Owner: ${var.aws.owner}
EOT

  output_vpc = length(module.vpc) == 0 ? "No VPC deployed" : <<EOT
VPC Information:
${join("\n", [
  for vpc_key, vpc_value in module.vpc : (
    "→ (${vpc_key})${vpc_value.name}:\n\t╠ ID: ${vpc_value.vpc_id}\n\t╠ Public Subnets: ${join(", ", try(vpc_value.public_subnets, []))}\n\t╠ Private Subnets: ${join(", ", try(vpc_value.private_subnets, []))}\n\t╠ Database Subnets: ${join(", ", try(vpc_value.database_subnets, []))}\n\t╚ Elasticache Subnets: ${join(", ", try(vpc_value.elasticache_subnets, []))}"
  )
])}
EOT

output_eks = length(module.eks) == 0 ? "No EKS clusters deployed" : <<EOT
EKS Information:
${join("\n", [
for eks_key, eks_value in module.eks : (
  "→ (${eks_key})${eks_value.cluster_name}:\n\t╚ oidc_provider_arn: ${eks_value.oidc_provider_arn}"
)
])}
EOT

output_rds = length(module.rds) == 0 ? "No RDS clusters deployed" : <<EOT
RDS Information:
${join("\n", [
for key, value in module.rds : (
  "→ (${key})${value.db_instance_identifier}:\n\t╠ Endpoint: ${value.db_instance_endpoint}\n\t╠ Port: ${value.db_instance_port}\n\t╠ Engine: ${value.db_instance_engine}\n\t╠ Version: ${value.db_instance_engine_version_actual}\n\t╠ Username: ${value.db_instance_username}\n\t╚ Password: ${var.aws.resources.rds[key].password == null || var.aws.resources.rds[key].password == "" ? random_password.rds[key].result : var.aws.resources.rds[key].password}"
)
])}
EOT

}


