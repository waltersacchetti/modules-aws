resource "random_password" "rds" {
  for_each         = var.aws.resources.rds
  length           = 16
  special          = true
  upper            = true
  lower            = true
  number           = true
  override_special = "!@#$%^&*()-_=+[]{}|:;<>?,./"
}

module "rds" {
  source     = "terraform-aws-modules/rds/aws"
  for_each   = var.aws.resources.rds
  tags       = merge(local.common_tags, each.value.tags)
  identifier = "${var.aws.region}-${var.aws.profile}-rds-${each.key}"

  db_subnet_group_name   = module.vpc[each.value.vpc].database_subnet_group
  create_db_subnet_group = each.value.create_db_subnet_group

  engine               = each.value.engine
  engine_version       = each.value.engine_version
  family               = each.value.family
  major_engine_version = each.value.major_engine_version

  instance_class    = each.value.instance_class
  allocated_storage = each.value.allocated_storage

  db_name                             = each.value.db_name
  username                            = each.value.username
  password                            = each.value.password == null || each.value.password == "" ? random_password.rds[each.key].result : each.value.password
  port                                = each.value.port
  iam_database_authentication_enabled = each.value.iam_db_auth_enabled

  #Maintenance
  maintenance_window  = each.value.maintenance_window
  backup_window       = each.value.backup_window
  deletion_protection = each.value.deletion_protection

  #AZ
  availability_zone = each.value.multi_az == false ? module.vpc[each.value.vpc].azs[0] : null
  multi_az          = each.value.multi_az
}