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
  /*
          instance_refresh = {
              strategy = "Rolling"
              preferences = {
              checkpoint_delay       = 600
              checkpoint_percentages = [35, 70, 100]
              instance_warmup        = 300
              min_healthy_percentage = 50
              }
              triggers = ["tag"]
          }
      */
  launch_template_name        = each.value.launch_template_name
  launch_template_description = each.value.launch_template_description
  update_default_version      = each.value.update_default_version
  image_id                    = each.value.image_id
  instance_type               = each.value.instance_type
  ebs_optimized               = each.value.ebs_optimized
  enable_monitoring           = each.value.enable_monitoring
  # IAM role & instance profile
  create_iam_instance_profile = each.value.create_iam_instance_profile
  iam_role_name               = each.value.iam_role_name
  iam_role_path               = each.value.iam_role_path
  iam_role_description        = each.value.iam_role_description
  /*
    iam_role_tags               = [
      for value in each.value.iam_role_tags : {
        CustomIamRole = value.CustomIamRole
        }
    ]
    iam_role_policies           = [
      for value in each.value.iam_role_policies : {
        AmazonSSMManagedInstanceCore = value.AmazonSSMManagedInstanceCore
        }
    ]
    */
  iam_role_tags         = each.value.iam_role_tags
  iam_role_policies     = each.value.iam_role_policies
  block_device_mappings = each.value.block_device_mappings
}