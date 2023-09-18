variable "aws" {
  description = "Main AWS Configuration"
  type = object({
    region  = string
    profile = string
    owner   = string
    project = string
    tags    = optional(map(string), {})
    resources = object({
      alternat = optional(object({
        image_uri           = optional(string, "0123456789012.dkr.ecr.us-east-1.amazonaws.com/alternat-functions-lambda")
        image_tag           = optional(string, "v0.3.3")
        instance_type       = optional(string, "c6gn.large")
        lambda_package_type = optional(string, "Zip")
        sgs                 = optional(list(string), [])
        vpc                 = optional(string, null)
      }), {})
      asg = optional(map(object({
        min_size          = optional(number, 1)
        max_size          = optional(number, 1)
        desired_capacity  = optional(number, 1)
        health_check_type = optional(string, null)
        subnets           = list(string)
        vpc               = string
        image_id          = optional(string, null)
        instance_type     = optional(string, null)
        ebs_optimized     = optional(bool, false)
        enable_monitoring = optional(bool, false)
        user_data_script  = optional(string, null)
        root_volume_size  = optional(number, 20)
        sg                = string
        iam_role_policies = optional(map(string), {})
        tags              = optional(map(string), {})
        lb_target_group   = optional(string, null)
        block_device_mappings = optional(list(object({
          device_name = string
          ebs = optional(object({
            delete_on_termination = optional(bool, null)
            encrypted             = optional(bool, null)
            volume_size           = optional(number, null)
            volume_type           = optional(string, null)
          }), null)
        })), [])
        metadata_options = optional(map(string), {})
        network_interfaces = optional(list(object({
          delete_on_termination = bool
          description           = string
          security_groups       = list(string)
        })), [])
      })), {})
      cloudfront_cache_policies = optional(map(object({
        name        = string
        min_ttl     = number
        max_ttl     = optional(number, 1)
        default_ttl = optional(number, 1)
        parameters_in_cache_key_and_forwarded_to_origin = object({
          enable_accept_encoding_brotli = optional(bool, false)
          enable_accept_encoding_gzip   = optional(bool, false)
          cookies_config = object({
            cookie_behavior = string #none, whitelist, allEscept, all
            #cookies = list(string)
          })
          headers_config = object({
            header_behavior = string #none, whitelist
            #headers = list(string)
          })
          query_strings_config = object({
            query_string_behavior = string                #none,whitelist, allExcept, all
            enable_query_strings  = optional(bool, false) # Enable "query_strings" block or not
            query_strings         = optional(list(string), null)
          })
        })
      })), {})
      cloudfront_distributions = optional(map(object({
        enabled      = bool
        http_version = optional(string, "http2")
        #web_acl_id = string
        origin = object({
          domain_name = string # This value is AWS global
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
          compress               = optional(bool, false)
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
        ordered_cache_behavior = optional(map(object({
          allowed_methods        = list(string)
          cache_policy_id        = string # Required for mapping the cache policies
          cached_methods         = list(string)
          compress               = optional(bool, false)
          path_pattern           = string
          viewer_protocol_policy = string
        })), {})
        tags = optional(map(string), {})
      })), {})
      ec2 = optional(map(object({
        instance_type               = optional(string, "t3.micro")
        key_name                    = optional(string, null)
        monitoring                  = optional(bool, false)
        ami                         = optional(string, null)
        vpc                         = optional(string, null)
        subnet                      = optional(string, null)
        sg                          = optional(string, null)
        key_pair_tags               = optional(map(string), {})
        user_data                   = optional(string, null)
        user_data_replace_on_change = optional(bool, null)
        tags                        = optional(map(string), {})
        root_block_device = optional(object({
          encrypted   = optional(bool, false)
          volume_type = optional(string, "gp3")
          throughput  = optional(number, 125)
          volume_size = optional(number, 100)
          tags        = optional(map(string), {})
        }), {})
        ebs_block_device = optional(map(object({
          encrypted   = optional(bool, false)
          volume_type = optional(string, "gp3")
          throughput  = optional(number, 125)
          volume_size = optional(number, 100)
          tags        = optional(map(string), {})
        })), {})
        iam_role_policies = optional(map(string), null)
        network_interfaces = optional(list(object({
          vpc    = string
          subnet = string
          sg     = string
        })), [])
      })), {})
      elc = optional(map(object({
        engine                  = optional(string, "redis")
        engine_version          = optional(string, "7.0")
        node_type               = optional(string, "cache.m6g.large")
        num_cache_nodes         = optional(number, 1)
        num_cache_clusters      = optional(number, 0)
        num_node_groups         = optional(number, 2)
        replicas_per_node_group = optional(number, 1)
        parameter_group_name    = optional(string, "default.redis7.cluster.on")
        subnets                 = optional(list(string), [])
        sg                      = string
        vpc                     = string
        tags                    = optional(map(string), {})
      })), {})
      # The eks module can't define multiple cluster, force to only one called main
      eks = optional(map(object({
        tags            = optional(map(string), {})
        cluster_version = optional(string, "1.26")

        vpc     = string
        subnets = list(string)
        sg      = string
        public  = optional(bool, true)
        cicd    = optional(bool, true)

        aws_auth_roles = optional(list(object({
          arn      = string
          username = string
          groups   = optional(list(string), [])
        })), [])

        iam_role_additional_policies = optional(map(string), null)

        eks_managed_node_groups = optional(map(object({
          ami_type              = optional(string, "AL2_x86_64")
          desired_size          = optional(number, 1)
          max_size              = optional(number, 2)
          min_size              = optional(number, 1)
          instance_type         = optional(string, "t3.medium")
          kubelet_extra_args    = optional(string, "")
          subnets               = optional(list(string), [])
          block_device_mappings = optional(map(map(any)), null)
          labels                = optional(map(string), {})
          taints = optional(list(object({
            key    = string
            value  = string
            effect = string
          })), [])
          tags = optional(map(string), {})
        })), {})
        role_binding = optional(list(object({
          username    = string
          clusterrole = string
          namespaces  = list(string)
        })), [])
        cluster_role_binding = optional(list(object({
          username    = string
          clusterrole = string
        })), [])
        namespaces     = optional(list(string), [])
        cluster_addons = optional(map(map(string)), null)
      })), {})
      iam = optional(map(object({
        create_iam_role                   = optional(bool, false)
        create_iam_policy                 = optional(bool, false)
        create_iam_role_policy_attachment = optional(bool, false)
        create_iam_instance_profile       = optional(bool, false)
        iam_role = optional(object({
          assume_role_policy = optional(object({
            effect         = optional(string, "Allow")
            principal_type = string
            actions        = list(string)
            identifiers    = list(string)
          }), null)
          tags = optional(map(string), {})
        }), {})
        iam_policy = optional(object({
          policies = optional(map(object({
            actions   = list(string)
            prefix    = optional(string, "")
            effect    = optional(string, "Allow")
            resources = list(string)
          })), {})
          tags = optional(map(string), {})
        }), {})
        iam_role_policy_attachment = optional(object({
          iam_policy = optional(string, null)
          role       = optional(string, null)
        }), {})
        iam_instance_profile = optional(object({
          role = optional(string, null)
          tags = optional(map(string), {})
        }), {})
      })), {})
      kinesis = optional(map(object({
        data_retention_in_hours = optional(number, 0)
        media_type              = optional(string, null)
        tags                    = optional(map(string), {})
        region                  = optional(string, null)
      })), {})
      lb = optional(map(object({
        load_balancer_type               = string
        internal                         = optional(bool, false)
        vpc                              = string
        sg                               = optional(string, null)
        subnets                          = list(string)
        enable_cross_zone_load_balancing = optional(bool, false)
        enable_deletion_protection       = optional(bool, false)
        tags                             = optional(map(string), {})
        http_tcp_listeners = optional(list(object({
          port               = number
          protocol           = string
          target_group_index = number
        })), [])
        target_groups = optional(list(object({
          backend_protocol       = optional(string, null)
          backend_port           = optional(number, null)
          target_type            = optional(string, null)
          deregistration_delay   = optional(number, null)
          connection_termination = optional(bool, null)
          preserve_client_ip     = optional(bool, null)
          health_check = optional(object({
            interval            = optional(number, null)
            path                = optional(string, null)
            matcher             = optional(string, null)
            port                = optional(string, null)
            protocol            = optional(string, null)
            healthy_threshold   = optional(number, null)
            unhealthy_threshold = optional(number, null)
            timeout             = optional(number, null)
          }), null)
          tags = optional(map(string), {})
          stickiness = optional(object({
            type            = optional(string, "source_ip")
            cookie_duration = optional(number, null)
          }), null)
        })), [])
      })), {})
      mq = optional(map(object({
        tags           = optional(map(string), {})
        vpc            = string
        sg             = string
        subnets        = list(string)
        engine_type    = optional(string, "ActiveMQ")
        engine_version = optional(string, "5.16.4")
        # SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, and CLUSTER_MULTI_AZ
        deployment_mode    = optional(string, "SINGLE_INSTANCE")
        host_instance_type = optional(string, "mq.m5.large")
        username           = optional(string, "master")
        password           = optional(string, null)
        configuration      = optional(string, "")
      })), {})
      rds = optional(map(object({
        tags                   = optional(map(string), {})
        vpc                    = string
        sg                     = string
        engine                 = optional(string, "postgres")
        engine_version         = optional(string, "12.11")
        family                 = optional(string, "postgres12")
        major_engine_version   = optional(string, "12.11")
        instance_class         = optional(string, "db.r6g.large")
        allocated_storage      = optional(number, 100)
        db_name                = optional(string, "master")
        username               = optional(string, "master")
        password               = optional(string, null)
        port                   = optional(number, null)
        iam_db_auth_enabled    = optional(bool, true)
        maintenance_window     = optional(string, "Mon:00:00-Mon:03:00")
        backup_window          = optional(string, "03:00-06:00")
        create_db_subnet_group = optional(bool, false)
        deletion_protection    = optional(bool, false)
        multi_az               = optional(bool, false)
        publicly_accessible    = optional(bool, false)
        databases              = optional(list(string), [])
      })), {})
      s3 = optional(map(object({
        force_destroy = optional(bool, false)
        # object_lock_configuration = object({
        #   rule = object({
        #     default_retention = map(string)
        #   })
        # })
        bucket_policy_statements = optional(map(object({
          principal_type = string
          iam_role       = list(string)
          actions        = list(string)
          prefix         = optional(string, "")
          effect         = optional(string, "Allow")
        })), {})
        versioning = map(bool)
        iam        = string
        tags       = optional(map(string), {})
      })), {})
      sg = optional(map(object({
        tags              = optional(map(string), {})
        vpc               = string
        egress_restricted = optional(bool, true)
        ingress_open      = optional(bool, false)
        ingress = optional(list(object({
          ports = list(object({
            from = number
            to   = optional(number, null)
          }))
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
        enable_vpn_gateway   = optional(bool, false)
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

        vgw_dx = optional(map(object({
          account_id = string
          dx_gw_id   = string
        })), {})

        private_nat_gateway = optional(list(string), [])
        aws_route = optional(map(list(object({
          cidr_block          = string
          private_nat_gateway = optional(string, null)
          transit_gateway     = optional(string, null)
        }))), {})
      })), {})
      vpn = optional(map(object({
        sg   = string
        vpc  = string
        type = optional(string, "certificate")

        tags                  = optional(map(string), {})
        client_cidr_block     = optional(string, "192.168.100.0/22")
        transport_protocol    = optional(string, null)
        split_tunnel          = optional(bool, true)
        vpn_port              = optional(number, 443)
        session_timeout_hours = optional(number, 8)

        saml_file = optional(string, null)

        subnets             = optional(list(string), ["app-a"])
        target_network_cidr = optional(string, "0.0.0.0/0")
      })), {})
      waf = optional(map(object({
        scope = string
        visibility_config = object({
          cloudwatch_metrics_enabled = bool
          sampled_requests_enabled   = bool
        })
        rules = optional(map(object({
          priority = number
          statement = object({
            name        = string
            vendor_name = string
          })
          visibility_config = object({
            cloudwatch_metrics_enabled = bool
            sampled_requests_enabled   = bool
          })
        })), {})
        tags = optional(map(string), {})
      })), {})
    })
  })
}