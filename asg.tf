module "asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  for_each                  = var.aws.resources.asg
  name                      = "${var.aws.region}-${var.aws.profile}-asg-${each.key}"
  min_size                  = each.value.min_size
  max_size                  = each.value.max_size
  desired_capacity          = each.value.desired_capacity
  wait_for_capacity_timeout = each.value.wait_for_capacity_timeout
  health_check_type         = each.value.health_check_type
  vpc_zone_identifier       = data.aws_subnets.asg_network[each.key].ids
  image_id                  = each.value.image_id
  instance_type             = each.value.instance_type
  tags                      = merge(local.common_tags, each.value.tags)
}