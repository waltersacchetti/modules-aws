module "asg" {
  source                      = "terraform-aws-modules/autoscaling/aws"
  version                     = "6.10.0"
  for_each                    = var.aws.resources.asg
  name                        = "${var.aws.region}-${var.aws.profile}-asg-${each.key}"
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
  iam_role_name               = "iam-role-${var.aws.region}-${var.aws.profile}-asg-${each.key}"
  iam_role_use_name_prefix    = true
  block_device_mappings       = [
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
  metadata_options            = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  network_interfaces          = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.sg[each.value.sg].security_group_id]
    }
  ]
  user_data                   = base64encode(each.value.user_data_script)
  tags                        = merge(local.common_tags, each.value.tags)

  # The LB ARN is directly assigned without deploying an aws_autoscaling_attachment resource since this would change the state of the ASG module
  target_group_arns           = [aws_lb_target_group.this[each.value.lb-tg].arn]

  # Making it dependient of all the resources of LB otherwise it would change the state of the ASG module in every plan/apply
  depends_on                  = [
    aws_lb.this,
    aws_lb_target_group.this,
    aws_lb_listener.this
  ]
}