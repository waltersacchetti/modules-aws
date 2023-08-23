resource "aws_lb_target_group" "this" {
  for_each = var.aws.resources.lb
  name     = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-lb-${each.key}"
  port     = each.value.application_port
  protocol = each.value.application_protocol
  vpc_id   = module.vpc[each.value.vpc].vpc_id

  health_check { #TODO: DEFINE IT
    interval            = 5
    path                = "/"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-301"
  }
  tags = merge(local.common_tags, each.value.tags)

}

resource "aws_lb" "this" {
  for_each                         = var.aws.resources.lb
  name                             = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-nlb-${each.key}"
  load_balancer_type               = "network"
  internal                         = each.value.private_lb
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  subnets                          = data.aws_subnets.lb_network[each.key].ids
  tags                             = merge(local.common_tags, each.value.tags)
}

resource "aws_lb_listener" "this" {
  for_each          = var.aws.resources.lb
  load_balancer_arn = aws_lb.this[each.key].arn
  port              = each.value.lb_port
  protocol          = each.value.lb_protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
  tags = merge(local.common_tags, each.value.tags)
}