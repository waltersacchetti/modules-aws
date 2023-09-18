# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Data                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
data "aws_subnets" "lb_network" {
  for_each = var.aws.resources.lb
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = [for key in each.value.subnets : join(",", ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${key}"])]
  }
}

# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
module "lb" {
  source                           = "terraform-aws-modules/alb/aws"
  version                          = "8.7.0"
  for_each                         = var.aws.resources.lb
  name                             = each.value.load_balancer_type == "network" ? "${local.translation_regions[var.aws.region]}-${var.aws.profile}-nlb-${each.key}" : "${local.translation_regions[var.aws.region]}-${var.aws.profile}-alb-${each.key}"
  load_balancer_type               = each.value.load_balancer_type
  internal                         = each.value.internal
  vpc_id                           = module.vpc[each.value.vpc].vpc_id
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing
  enable_deletion_protection       = each.value.enable_deletion_protection
  subnets                          = data.aws_subnets.lb_network[each.key].ids
  security_groups                  = each.value.sg != null ? [module.sg[each.value.sg].security_group_id] : null
  tags                             = merge(local.common_tags, each.value.tags)
  http_tcp_listeners = length(each.value.http_tcp_listeners) == 0 ? [] : [
    for key, value in each.value.http_tcp_listeners :
    {
      port               = value.port
      protocol           = value.protocol
      target_group_index = value.target_group_index
    }
  ]
  target_groups = length(each.value.target_groups) == 0 ? [] : [
    for key, value in each.value.target_groups :
    {
      name                   = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-lb-tg-${key}-${each.key}"
      backend_protocol       = value.backend_protocol
      backend_port           = value.backend_port
      target_type            = value.target_type
      deregistration_delay   = value.deregistration_delay
      connection_termination = contains(["UDP", "TCP_UDP"], value.backend_protocol) && value.connection_termination == null ? true : value.connection_termination
      preserve_client_ip     = value.preserve_client_ip
      health_check = value.health_check == null ? { # Default health_check if not set
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        port                = "traffic-port"
        protocol            = "TCP"
        timeout             = 10
        unhealthy_threshold = 2
        } : {
        enabled             = true
        interval            = value.health_check.interval
        path                = value.health_check.path
        matcher             = value.health_check.matcher
        port                = value.health_check.port
        protocol            = value.health_check.protocol
        healthy_threshold   = value.health_check.healthy_threshold
        unhealthy_threshold = value.health_check.unhealthy_threshold
        timeout             = value.health_check.timeout
      }
      stickiness = value.stickiness == null ? { # Default stickiness if not set
        enabled = false
        type    = "source_ip"
        } : {
        enabled         = true
        type            = value.stickiness.type
        cookie_duration = value.stickiness.cookie_duration
      }
      tags = merge(local.common_tags, value.tags)
    }
  ]
}
