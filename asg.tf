# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Data                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
data "aws_subnets" "asg_network" {
  for_each = var.aws.resources.asg
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
module "asg" {
  source                      = "terraform-aws-modules/autoscaling/aws"
  version                     = "6.10.0"
  for_each                    = var.aws.resources.asg
  name                        = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-asg-${each.key}"
  min_size                    = each.value.min_size
  max_size                    = each.value.max_size
  desired_capacity            = each.value.desired_capacity
  health_check_type           = each.value.health_check_type
  vpc_zone_identifier         = data.aws_subnets.asg_network[each.key].ids
  image_id                    = each.value.image_id
  instance_type               = each.value.instance_type
  ebs_optimized               = each.value.ebs_optimized
  enable_monitoring           = each.value.enable_monitoring
  create_iam_instance_profile = true
  iam_role_policies           = each.value.iam_role_policies
  iam_role_name               = "iam-role-${local.translation_regions[var.aws.region]}-${var.aws.profile}-asg-${each.key}"
  iam_role_use_name_prefix    = true
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = each.value.root_volume_size
        volume_type           = "gp3"
      }
    },
  ]
  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.sg[each.value.sg].security_group_id]
    }
  ]
  user_data = base64encode(each.value.user_data_script)
  tags      = merge(local.common_tags, each.value.tags)

  # The LB ARN is directly assigned without deploying an aws_autoscaling_attachment resource since this would change the state of the ASG module
  target_group_arns = [aws_lb_target_group.asg[each.key].arn]

  # Making it dependient of all the resources of LB otherwise it would change the state of the ASG module in every plan/apply
  depends_on = [
    aws_lb.asg,
    aws_lb_target_group.asg,
    aws_lb_listener.asg
  ]
}

resource "aws_lb_target_group" "asg" {
  for_each = var.aws.resources.asg
  name     = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-lb-asg-${each.key}"
  port     = each.value.lb_target_group.application_port
  protocol = each.value.lb_target_group.application_protocol
  vpc_id   = module.vpc[each.value.vpc].vpc_id

  health_check {
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

resource "aws_lb" "asg" {
  for_each                         = var.aws.resources.asg
  name                             = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-nlb-asg-${each.key}"
  load_balancer_type               = "network"
  internal                         = each.value.lb.private_lb
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  subnets                          = data.aws_subnets.asg_network[each.key].ids
  tags                             = merge(local.common_tags, each.value.tags)
}

resource "aws_lb_listener" "asg" {
  for_each          = var.aws.resources.asg
  load_balancer_arn = aws_lb.asg[each.key].arn
  port              = each.value.lb_listener.lb_port
  protocol          = each.value.lb_listener.lb_protocol
  ssl_policy        = each.value.lb_listener.ssl_policy
  certificate_arn   = each.value.lb_listener.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg[each.key].arn
  }
  tags = merge(local.common_tags, each.value.tags)
}