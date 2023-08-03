module "asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "6.10.0"
  for_each                  = var.aws.resources.asg
  name                      = "${var.aws.region}-${var.aws.profile}-asg-${each.key}"
  min_size                  = each.value.min_size
  max_size                  = each.value.max_size
  desired_capacity          = each.value.desired_capacity
  wait_for_capacity_timeout = each.value.wait_for_capacity_timeout
  health_check_type         = each.value.health_check_type
  vpc_zone_identifier       = data.aws_subnets.asg_network[each.key].ids
  tags                      = merge(local.common_tags, each.value.tags)
  initial_lifecycle_hooks = [
    for ilh in each.value.initial_lifecycle_hooks : {
      name                  = ilh.name
      default_result        = ilh.default_result
      heartbeat_timeout     = ilh.heartbeat_timeout
      lifecycle_transition  = ilh.lifecycle_transition
      notification_metadata = jsonencode(ilh.notification_metadata)
    }
  ]
  instance_refresh                   = each.value.instance_refresh
  launch_template_name               = each.value.launch_template_name
  launch_template_description        = each.value.launch_template_description
  update_default_version             = each.value.update_default_version
  image_id                           = each.value.image_id
  instance_type                      = each.value.instance_type
  ebs_optimized                      = each.value.ebs_optimized
  enable_monitoring                  = each.value.enable_monitoring
  create_iam_instance_profile        = each.value.create_iam_instance_profile
  iam_role_name                      = each.value.iam_role_name
  iam_role_path                      = each.value.iam_role_path
  iam_role_description               = each.value.iam_role_description
  iam_role_tags                      = each.value.iam_role_tags
  iam_role_policies                  = each.value.iam_role_policies
  block_device_mappings              = each.value.block_device_mappings
  capacity_reservation_specification = each.value.capacity_reservation_specification
  cpu_options                        = each.value.cpu_options
  credit_specification               = each.value.credit_specification
  instance_market_options            = each.value.instance_market_options[0]
  metadata_options                   = each.value.metadata_options
  network_interfaces = [
    for nit in each.value.network_interfaces : {
      delete_on_termination = nit.delete_on_termination
      description           = nit.description
      device_index          = nit.device_index
      security_groups       = [module.sg[nit.security_groups].security_group_id]
    }
  ]
  placement          = each.value.placement
  tag_specifications = each.value.tag_specifications
}