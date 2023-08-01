module "sg" {
  source   = "terraform-aws-modules/security-group/aws"
  version  = "5.1.0"
  for_each = var.aws.resources.sg
  name     = "${var.aws.region}-${var.aws.profile}-sg-${each.key}"
  vpc_id   = module.vpc[each.value.vpc].vpc_id
  tags     = merge(local.common_tags, each.value.tags)
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "sg_ingress_rules" {
  source            = "terraform-aws-modules/security-group/aws"
  version           = "5.1.0"
  for_each          = var.aws.resources.sg_ingress_rules
  create_sg         = false
  security_group_id = module.sg[each.key].security_group_id
  ingress_with_source_security_group_id = [
    for value in each.value.ingress : {
      from_port                = value.port
      to_port                  = value.port
      protocol                 = value.protocol
      source_security_group_id = module.sg[value.source_security_group].security_group_id
      description              = "${value.protocol}/${value.port} - Access from ${value.source_security_group} to ${each.key}"
    }
  ]
}