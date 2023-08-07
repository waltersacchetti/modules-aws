variable "aws" {
  description = "Main AWS Configuration"
  type = object({
    region  = string
    profile = string
    owner   = string
    resources = object({
      elc = map(object({
        engine               = string
        engine_version       = string
        node_type            = string
        num_cache_nodes      = number
        parameter_group_name = string
        port                 = number
        security_group       = string
        vpc                  = string
        tags                 = map(any)
      }))
      asg = map(object({
        min_size                  = number
        max_size                  = number
        desired_capacity          = number
        wait_for_capacity_timeout = string
        health_check_type         = string
        vpc_zone_identifier       = list(string)
        vpc                       = string
        initial_lifecycle_hooks = list(object({
          name                  = string
          default_result        = string
          heartbeat_timeout     = string
          lifecycle_transition  = string
          notification_metadata = map(string)
        }))
        instance_refresh = object({
          strategy = string
          preferences = object({
            checkpoint_delay       = number
            checkpoint_percentages = list(number)
            instance_warmup        = number
            min_healthy_percentage = number
          })
          triggers = list(string)
        })
        launch_template_name        = string
        launch_template_description = string
        update_default_version      = string
        image_id                    = string
        instance_type               = string
        ebs_optimized               = bool
        enable_monitoring           = bool
        # IAM role & instance profile
        create_iam_instance_profile = bool
        iam_role_name               = string
        iam_role_path               = string
        iam_role_description        = string
        iam_role_tags               = map(string)
        iam_role_policies           = map(string)
        iam_role_tags               = map(string)
        iam_role_policies           = map(string)
        block_device_mappings = list(object({
          device_name = string
          no_device   = number
          ebs = list(object({
            delete_on_termination = bool
            encrypted             = bool
            volume_size           = number
            volume_type           = string
          }))
        }))
        capacity_reservation_specification = map(string)
        cpu_options                        = map(string)
        credit_specification               = map(string)
        instance_market_options = list(object({
          market_type = string
          spot_options = list(object({
            block_duration_minutes = number
          }))
        }))
        metadata_options = map(string)
        network_interfaces = list(object({
          delete_on_termination = bool
          description           = string
          device_index          = number
          security_groups       = string
        }))
        placement = map(string)
        tag_specifications = list(object({
          resource_type = string
          tags          = map(string)
        }))
        tags = map(any)
      }))
      # The eks module can't define multiple cluster, force to only one called main
      eks = map(object({
        tags            = map(any)
        cluster_version = string

        vpc     = string
        subnets = list(string)
        sg      = string
        public  = bool

        aws_auth_roles = list(object({
          arn      = string
          username = string
          groups   = list(string)
        }))

        eks_managed_node_groups = map(object({
          ami_type           = string
          desired_capacity   = number
          max_size           = number
          min_size           = number
          instance_type      = string
          disk_size          = number
          kubelet_extra_args = string
        }))
        role_binding = list(object({
          username    = string
          clusterrole = string
          namespace   = string
        }))
        cluster_role_binding = list(object({
          username    = string
          clusterrole = string
        }))
        namespaces = list(string)
      }))
      rds = map(object({
        tags                   = map(any)
        vpc                    = string
        sg                     = string
        engine                 = string
        engine_version         = string
        instance_class         = string
        allocated_storage      = number
        db_name                = string
        username               = string
        password               = string
        port                   = string
        iam_db_auth_enabled    = bool
        maintenance_window     = string
        backup_window          = string
        create_db_subnet_group = bool
        subnet_ids             = list(string)
        family                 = string
        major_engine_version   = string
        deletion_protection    = bool
        multi_az               = bool
      }))
      sg = map(object({
        tags              = map(any)
        vpc               = string
        egress_restricted = bool
        ingress = list(object({
          port                  = number
          protocol              = string
          source_security_group = string
        }))
      }))
      vpc = map(object({
        tags                  = map(any)
        cidr                  = string
        secondary_cidr_blocks = list(string)
        azs                   = list(string)

        enable_nat_gateway   = bool
        single_nat_gateway   = bool
        enable_vpn_gateway   = bool
        enable_dns_hostnames = bool
        enable_dns_support   = bool

        public_subnets  = map(string)
        private_subnets = map(string),

        create_database_subnet_group           = bool
        create_database_subnet_route_table     = bool
        create_database_internet_gateway_route = bool
        database_subnets                       = map(string)

        create_elasticache_subnet_group       = bool
        create_elasticache_subnet_route_table = bool
        elasticache_subnets                   = map(string)
      }))
      mq = map(object({
        tags               = map(any)
        vpc                = string
        subnets            = list(string)
        engine_type        = string
        engine_version     = string
        deployment_mode    = string
        host_instance_type = string
        sg                 = string
        username           = string
        password           = string
        configuration      = string
      }))
      kinesis = map(object({
        data_retention_in_hours = number
        media_type              = string
        tags                    = map(any)
      }))
    })
  })
}
variable "translation_regions" {
  type        = map(string)
  description = "Map of region names to their corresponding names in the AWS account"
  default = {
    "euw1" = "eu-west-1"
  }
}

variable "translation_environments" {
  type        = map(string)
  description = "Map of environment names to their corresponding names in the AWS account"
  default = {
    "tst"  = "test"
    "dev"  = "development"
    "prod" = "production"
    "pre"  = "preproduction"
    "qa"   = "qualityassurance"
  }
}