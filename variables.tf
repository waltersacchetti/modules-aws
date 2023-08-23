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
        min_size          = number
        max_size          = number
        desired_capacity  = number
        health_check_type = string
        subnets           = list(string)
        vpc               = string
        image_id          = string
        instance_type     = string
        ebs_optimized     = bool
        enable_monitoring = bool
        user_data_script  = string
        root_volume_size  = number
        sg                = string
        iam_role_policies = map(string)
        tags              = map(any)
        lb-tg             = string
      })), {})
      lb = optional(map(object({
        vpc                  = string
        subnets              = list(string)
        application_port     = number
        application_protocol = string
        private_lb           = bool
        lb_port              = number
        lb_protocol          = string
        ssl_policy           = string
        certificate_arn      = string
        tags                 = map(any)
      })), {})
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
        tags              = optional(map(string), {})
        vpc               = string
        egress_restricted = optional(bool, true)
        ingress_open      = optional(bool, false)
        ingress = optional(list(object({
          from_port              = number
          to_port                = optional(number, null)
          protocol               = optional(string, "tcp")
          source_security_groups = list(string)
        })), [])
      })), {})
      vpc = optional(map(object({
        tags                  = optional(map(string), {})
        cidr                  = string
        secondary_cidr_blocks = optional(list(string), [])
        azs                   = list(string)

        enable_nat_gateway   = optional(bool, true)
        single_nat_gateway   = optional(bool, true)
        enable_vpn_gateway   = optional(bool, true)
        enable_dns_hostnames = optional(bool, true)
        enable_dns_support   = optional(bool, true)

        public_subnets  = optional(map(string), {})
        private_subnets = optional(map(string), {})

        create_database_subnet_group           = optional(bool, false)
        create_database_subnet_route_table     = optional(bool, null)
        create_database_internet_gateway_route = optional(bool, false)
        database_subnets                       = optional(map(string), {})

        create_elasticache_subnet_group       = optional(bool, false)
        create_elasticache_subnet_route_table = optional(bool, null)
        elasticache_subnets                   = optional(map(string), {})
      })), {})
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
        region                  = optional(string, null)
      })), {})
      vpn = optional(map(object({
        sg   = string
        vpc  = string
        type = optional(string, "certificate")

        tags                  = optional(map(string), {})
        client_cidr_block     = optional(string, "192.168.100.0/22")
        transport_protocol    = optional(string, "udp")
        split_tunnel          = optional(bool, true)
        vpn_port              = optional(number, 443)
        session_timeout_hours = optional(number, 8)

        saml_provider_arn          = optional(string, null)
        root_certificate_chain_arn = optional(string, null)

        subnets             = optional(list(string), ["app-a"])
        target_network_cidr = optional(string, "0.0.0.0/0")

      })), {})
      waf = optional(map(object({
        scope = string
        visibility_config = object({
          cloudwatch_metrics_enabled = bool
          sampled_requests_enabled   = bool
        })
        rules = map(object({
          priority = number
          statement = object({
            name        = string
            vendor_name = string
          })
          visibility_config = object({
            cloudwatch_metrics_enabled = bool
            sampled_requests_enabled   = bool
          })
        }))
        tags = map(any)
      })), {})
      cloudfront_distributions = optional(map(object({
        tags         = map(any)
        enabled      = bool
        http_version = string
        #web_acl_id = string
        origin = object({
          domain_name = optional(string)
          custom_origin_config = object({
            http_port              = number
            https_port             = number
            origin_protocol_policy = string
            origin_ssl_protocols   = list(string)
          })
        })
        default_cache_behavior = object({
          allowed_methods        = list(string)
          cached_methods         = list(string)
          viewer_protocol_policy = string
          compress               = bool
        })
        restrictions = object({
          locations        = list(string)
          restriction_type = string
        })
        viewer_certificate = object({
          #Currently hardcored cloudfront_default_certificate, other values can be  acm_certificate_arn, iam_certificate_id, minimum_protocol_version, ssl_support_method
          cloudfront_default_certificate = string
          minimum_protocol_version       = string
        })
        # Not configured by default
        #logging_config = object({
        #  bucket = string
        #  include_cookies = bool
        #})
        ordered_cache_behavior = map(object({
          allowed_methods        = list(string)
          cache_policy_id        = string
          cached_methods         = list(string)
          compress               = bool
          path_pattern           = string
          viewer_protocol_policy = string
        }))
      })), {})
      cloudfront_cache_policies = optional(map(object({
        name        = string
        min_ttl     = number
        max_ttl     = number
        default_ttl = number
        parameters_in_cache_key_and_forwarded_to_origin = object({
          enable_accept_encoding_brotli = bool
          enable_accept_encoding_gzip   = bool
          cookies_config = object({
            cookie_behavior = string #none, whitelist, allEscept, all
            #cookies = list(string)
          })
          headers_config = object({
            header_behavior = string #none, whitelist
            #headers = list(string)
          })
          query_strings_config = object({
            query_string_behavior = string #none,whitelist, allExcept, all
            enable_query_strings  = bool
            query_strings         = optional(list(string))
          })
        })
      })), {})
    })
  })
}