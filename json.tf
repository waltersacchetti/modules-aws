# ╔═════════════════════════════╗
# ║ Create RDS JSON              ║
# ╚═════════════════════════════╝

locals {
  json_rds = var.aws.resources.rds == 0 ? {} : {
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

resource "local_file" "json_rds" {
  count    = length(var.aws.resources.rds) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/json/rds.json"
  content  = jsonencode(local.json_rds)
}

locals {
  json_mq = var.aws.resources.mq == 0 ? {} : {
    for key, value in var.aws.resources.mq : key => {
      Engine    = aws_mq_broker.this[key].engine_type,
      Version   = aws_mq_broker.this[key].engine_version,
      Instances = aws_mq_broker.this[key].instances,
      Username  = value.username,
      Password  = value.password == null || value.password == "" ? random_password.mq[key].result : value.password
    }
  }
}

resource "local_file" "json_mq" {
  count    = length(var.aws.resources.mq) > 0 ? 1 : 0
  filename = "data/${terraform.workspace}/json/mq.json"
  content  = jsonencode(local.json_mq)
}