variable "aws" {
  description = "Main AWS Configuration"
  type = object({
    region  = string
    profile = string
    owner   = string
    resources = object({
      iam = optional(map(object({
        policy = string
        tags   = map(any)
      })), {})
      s3 = optional(map(object({
        force_destroy = bool
        # object_lock_configuration = object({
        #   rule = object({
        #     default_retention = map(string)
        #   })
        # })
        versioning = map(bool)
        iam        = string
        tags       = map(any)
      })), {})
      elc-memcached = optional(map(object({
        engine_version       = string
        node_type            = string
        num_cache_nodes      = number
        parameter_group_name = string
        sg                   = string
        vpc                  = string
        tags                 = map(any)
      })), {})
      elc-redis = optional(map(object({
        engine_version          = string
        node_type               = string
        num_cache_clusters      = number
        num_node_groups         = number
        replicas_per_node_group = number
        parameter_group_name    = string
        sg                      = string
        vpc                     = string
        tags                    = map(any)
      })), {})
      asg = optional(map(object({
        identifier            = string
        tags                  = map(string)
        ec2_config = object({
          instance_type         = string
          image_id              = string
          ec2_subnet_ids        = list(string)
          root_volume_size      = number
          ebs_optimized        = bool
          enable_monitoring    = bool
          sgs                   = list(string)
          user_data_script            = string
          application_port      = number
          application_protocol  = string
          health_check_type    = string
          iam_role_policies     = map(string)
        })
        load_balancer_config = object({
          lb_subnet_ids         = list(string)
          vpc_id                = string
          private_lb            = bool
          lb_port               = number
          lb_protocol           = string
          ssl_policy            = string
          certificate_arn       = string
        })  
      })),{})
      # The eks module can't define multiple cluster, force to only one called main
      eks = optional(map(object({
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
      })), {})
      rds = optional(map(object({
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
      })), {})
      sg = optional(map(object({
        tags              = map(any)
        vpc               = string
        egress_restricted = bool
        ingress = list(object({
          port                  = number
          protocol              = string
          source_security_group = string
        }))
      })), {})
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
      mq = optional(map(object({
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
      })), {})
      kinesis = optional(map(object({
        data_retention_in_hours = number
        media_type              = string
        tags                    = map(any)
      })), {})
      waf = optional(map(object({
        scope             = string
        visibility_config = object({
          cloudwatch_metrics_enabled = bool
          sampled_requests_enabled   = bool
        })
        rules = map(object({
          priority  = number
          statement = object({
            name        = string
            vendor_name = string
          })
          visibility_config = object({
            cloudwatch_metrics_enabled = bool
            sampled_requests_enabled   = bool
          })
        }))
        tags  = map(any)
      })),{})
    })
  })
}