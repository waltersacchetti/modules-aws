# ╔═════════════════════════════╗
# ║ Create RDS yaml             ║
# ╚═════════════════════════════╝

locals {
  yaml_rds = var.aws.resources.rds == 0 ? {} : {
    for key, value in var.aws.resources.rds : key => {
      Engine   = value.engine,
      Version  = value.engine_version,
      Endpoint = module.rds[key].db_instance_endpoint,
      Port     = module.rds[key].db_instance_port,
      Username = module.rds[key].db_instance_username,
      Password = value.password == null || value.password == "" ? random_password.rds[key].result : value.password,
      Databases = value.engine == "postgres" && length(value.databases) > 0 ? [
        for database in value.databases : {
          Database = database,
          Username = database,
          Password = random_password.rds_postgres_db["${key}_${database}"].result,
        }
      ] : null,
    }
  }
}

resource "local_file" "yaml_rds" {
  count    = length(var.aws.resources.rds) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/rds.yaml"
  content  = yamlencode(local.yaml_rds)
}

# ╔════════════════════════════╗
# ║ Create MQ yaml             ║
# ╚════════════════════════════╝

locals {
  yaml_mq = var.aws.resources.mq == 0 ? {} : {
    for key, value in var.aws.resources.mq : key => {
      Engine    = aws_mq_broker.this[key].engine_type,
      Version   = aws_mq_broker.this[key].engine_version,
      Instances = aws_mq_broker.this[key].instances,
      Username  = value.username,
      Password  = value.password == null || value.password == "" ? random_password.mq[key].result : value.password
    }
  }
}

resource "local_file" "yaml_mq" {
  count    = length(var.aws.resources.mq) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/mq.yaml"
  content  = yamlencode(local.yaml_mq)
}

# ╔═════════════════════════════╗
# ║ Create EC2 yaml             ║
# ╚═════════════════════════════╝

locals {
  yaml_ec2 = var.aws.resources.ec2 == 0 ? {} : {
    for key, value in var.aws.resources.ec2 : key => {
      Ami               = module.ec2[key].ami,
      Instance_Type     = value.instance_type,
      Private_Ip        = module.ec2[key].private_ip,
      Pem_Key_Location  = local_file.ec2-key[key].filename
    }
  }
}

resource "local_file" "yaml_ec2" {
  count    = length(var.aws.resources.ec2) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/ec2.yaml"
  content  = yamlencode(local.yaml_ec2)
}

# ╔══════════════════════════════════╗
# ║ Create IAM Role yaml             ║
# ╚══════════════════════════════════╝

locals {
  yaml_iam = var.aws.resources.iam == 0 ? {} : {
    for key, value in var.aws.resources.iam : key => {
      Name         = aws_iam_role.this[key].name,
      Description  = aws_iam_role.this[key].description,
      Role_Policy_To_Assume = aws_iam_role.this[key].assume_role_policy
    }
  }
}

resource "local_file" "yaml_iam" {
  count    = length(var.aws.resources.iam) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/iam.yaml"
  content  = yamlencode(local.yaml_iam)
}

# ╔════════════════════════════╗
# ║ Create S3 yaml             ║
# ╚════════════════════════════╝

locals {
  yaml_s3 = var.aws.resources.s3 == 0 ? {} : {
    for key, value in var.aws.resources.s3 : key => {
      Id          = module.s3[key].s3_bucket_id,
      Region      = module.s3[key].s3_bucket_region,
      Domain_Name = module.s3[key].s3_bucket_bucket_domain_name,
      Policy      = module.s3[key].s3_bucket_policy,
    }
  }
}

resource "local_file" "yaml_s3" {
  count    = length(var.aws.resources.s3) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/s3.yaml"
  content  = yamlencode(local.yaml_s3)
}


# ╔════════════════════════════╗
# ║ Create ASG yaml            ║
# ╚════════════════════════════╝

locals {
  yaml_asg = var.aws.resources.asg == 0 ? {} : {
    for key, value in var.aws.resources.asg : key => {
      Name                        = module.asg[key].autoscaling_group_name,
      Ami                         = value.image_id,
      Instance_Type               = value.instance_type,
      Desired_Size                = module.asg[key].autoscaling_group_desired_capacity,
      Min_Size                    = module.asg[key].autoscaling_group_min_size,
      Max_Size                    = module.asg[key].autoscaling_group_max_size,
      Subnets                     = module.asg[key].autoscaling_group_vpc_zone_identifier,
      Launch_Template_Name        = module.asg[key].launch_template_name
    }
  }
}

resource "local_file" "yaml_asg" {
  count    = length(var.aws.resources.asg) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/asg.yaml"
  content  = yamlencode(local.yaml_asg)
}


# ╔════════════════════════════╗
# ║ Create Load Balancer yaml  ║
# ╚════════════════════════════╝

locals {
  yaml_lb = var.aws.resources.lb == 0 ? {} : {
    for key, value in var.aws.resources.lb : key => {
      Load_Balancer               = {
        Name           = aws_lb.this[key].name,
        Type           = aws_lb.this[key].load_balancer_type,
        Subnets        = aws_lb.this[key].subnets
        Scheme         = aws_lb.this[key].internal == false ? "Internet-facing" : "Internal"
      }
      Lb_Target_Group                = {  
        Port           = aws_lb_target_group.this[key].port,
        Protocol       = aws_lb_target_group.this[key].protocol,
        Target_Type    = aws_lb_target_group.this[key].target_type,
        Health_Check   = aws_lb_target_group.this[key].health_check
      }
      Lb_Listener                    = {
        Port           = aws_lb_listener.this[key].port,
        Protocol       = aws_lb_listener.this[key].protocol,
        Ssl_Policy     = aws_lb_listener.this[key].ssl_policy
      }
    }
  }
}

resource "local_file" "yaml_lb" {
  count    = length(var.aws.resources.lb) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/lb.yaml"
  content  = yamlencode(local.yaml_lb)
}



# ╔════════════════════════════╗
# ║ Create Kinesis yaml        ║
# ╚════════════════════════════╝

locals {
  yaml_kinesis = var.aws.resources.kinesis == 0 ? {} : {
    for key, value in var.aws.resources.kinesis : key => {
      Name            = aws_kinesis_video_stream.this[key].name,
      Device_Name     = aws_kinesis_video_stream.this[key].device_name,
      Data_Retention  = aws_kinesis_video_stream.this[key].data_retention_in_hours,
      Media_Type      = aws_kinesis_video_stream.this[key].media_type,
      Version         = aws_kinesis_video_stream.this[key].version
    }
  }
}

resource "local_file" "yaml_kinesis" {
  count    = length(var.aws.resources.kinesis) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/kinesis.yaml"
  content  = yamlencode(local.yaml_kinesis)
}


# ╔════════════════════════════╗
# ║ Create WAF yaml            ║
# ╚════════════════════════════╝

locals {
  yaml_waf = var.aws.resources.waf == 0 ? {} : {
    for key, value in var.aws.resources.waf : key => {
      Name            = aws_wafv2_web_acl.this[key].name,
      Capacity        = aws_wafv2_web_acl.this[key].capacity,
      Scope           = aws_wafv2_web_acl.this[key].scope,
      Rules           = length(value.rules) > 0 ? [
        for rule in value.rules : {
          priority = rule.priority
          statement = rule.statement
        }
      ] : null,
    }
  }
}

resource "local_file" "yaml_waf" {
  count    = length(var.aws.resources.waf) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/waf.yaml"
  content  = yamlencode(local.yaml_waf)
}


# ╔════════════════════════════╗
# ║ Create VPC yaml            ║
# ╚════════════════════════════╝

locals {
  yaml_vpc = var.aws.resources.vpc == 0 ? {} : {
    for key, value in var.aws.resources.vpc : key => {
      Name            = module.vpc[key].name,
      Id              = module.vpc[key].vpc_id,
      Azs             = module.vpc[key].azs,
      Subnets         = {
        Private_Subnets     = module.vpc[key].private_subnets,
        Public_Subnets      = module.vpc[key].public_subnets,
        Database_subnets    = module.vpc[key].database_subnets,
        Elasticache_subnets = module.vpc[key].elasticache_subnets
      }
      Nat_Gw_Ids      = module.vpc[key].natgw_ids,
      Internet_Gw_Id  = module.vpc[key].igw_id
    }
  }
}

resource "local_file" "yaml_vpc" {
  count    = length(var.aws.resources.vpc) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/yaml/vpc.yaml"
  content  = yamlencode(local.yaml_vpc)
}
