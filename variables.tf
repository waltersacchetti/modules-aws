variable "aws" {
  description = "Main AWS Configuration"
  type = object({
    region  = string
    profile = string
    owner   = string
    resources = object({
      asg = map(object({
        min_size                  = number
        max_size                  = number
        desired_capacity          = number 
        wait_for_capacity_timeout = string   
        health_check_type         = string  
        vpc_zone_identifier       = list(string)
        vpc                       = string
        image_id                  = string
        instance_type             = string
        tags                      = map(any)
      }))
      eks = map(object({
        tags            = map(any)
        cluster_version = string
        vpc             = string
        subnets         = list(string)
      }))
      rds = map(object({
        tags                   = map(any)
        vpc                    = string
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
    })
  })
}
variable "translation_regions" {
  type = map(string)
  default = {
    "euw1" = "eu-west-1"
  }
}


variable "translation_environments" {
  type = map(string)
  default = {
    "tst"  = "test"
    "dev"  = "development"
    "prod" = "production"
    "pre"  = "preproduction"
    "qa"   = "qualityassurance"
  }
}