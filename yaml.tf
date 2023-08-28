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