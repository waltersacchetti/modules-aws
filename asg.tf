module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  for_each = var.aws.asg

  name = "${each.value.identifier}"

  vpc_zone_identifier = each.value.ec2_config.ec2_subnet_ids
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  health_check_type = each.value.ec2_config.health_check_type
  ebs_optimized     = each.value.ec2_config.ebs_optimized
  enable_monitoring = each.value.ec2_config.enable_monitoring

  image_id      = each.value.ec2_config.image_id
  instance_type = each.value.ec2_config.instance_type

  create_iam_instance_profile = true
  iam_role_policies = each.value.ec2_config.iam_role_policies
  iam_role_name = "iam-role-${each.value.identifier}"
  iam_role_use_name_prefix = true

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = each.value.ec2_config.root_volume_size
        volume_type           = "gp3"
      }
    },
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
  }
  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = each.value.ec2_config.sgs
    }
  ]
  user_data = base64encode(file("${path.module}/${each.value.ec2_config.user_data_script}"))


  tags = each.value.tags
}


resource "aws_lb_target_group" "tg" {
  for_each = var.aws.asg
  name     = "tg-${each.value.identifier}"
  port     = each.value.ec2_config.application_port
  protocol = each.value.ec2_config.application_protocol
  vpc_id   = each.value.load_balancer_config.vpc_id
  
  health_check  { #TODO: DEFINE IT
    interval            = 5
    path                = "/"
    protocol = "HTTP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-301"
  }
  tags = each.value.tags
  
}

resource "aws_lb" "nlb" {
  for_each = var.aws.asg
  name     = "lb-${each.value.identifier}"
  load_balancer_type = "network"
  internal           = each.value.load_balancer_config.private_lb
  enable_cross_zone_load_balancing = true 
  enable_deletion_protection = true
  subnets            = each.value.load_balancer_config.lb_subnet_ids
  tags = each.value.tags
}

resource "aws_lb_listener" "listener" {
  for_each = var.aws.asg
  load_balancer_arn = aws_lb.nlb[each.key].arn
  port              = each.value.load_balancer_config.lb_port
  protocol          = each.value.load_balancer_config.lb_protocol
  ssl_policy        = each.value.load_balancer_config.ssl_policy == "" ? null : each.value.load_balancer_config.ssl_policy
  certificate_arn   = each.value.load_balancer_config.certificate_arn == "" ? null : each.value.load_balancer_config.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }
  tags = each.value.tags
}

resource "aws_autoscaling_attachment" "asg_association" {
  for_each = var.aws.asg
  autoscaling_group_name = module.asg[each.key].autoscaling_group_id
  lb_target_group_arn   = aws_lb_target_group.tg[each.key].arn
}
