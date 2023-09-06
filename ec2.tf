# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Data                                             ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
data "aws_subnets" "ec2_network" {
  for_each = var.aws.resources.ec2
  filter {
    name   = "vpc-id"
    values = [module.vpc[each.value.vpc].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpc-${each.value.vpc}-${each.value.subnet}"]
  }
}

data "aws_ami" "amazon-linux-2" {
  owners = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  most_recent = true
}


# ╔══════════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                             Module                                           ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════════╝
resource "tls_private_key" "ec2_key" {
  for_each  = var.aws.resources.ec2
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ec2-key" {
  for_each        = var.aws.resources.ec2
  content         = tls_private_key.ec2_key[each.key].private_key_pem
  filename        = "data/${terraform.workspace}/ec2/${each.key}/${local.translation_regions[var.aws.region]}-${var.aws.profile}-key-pair-${each.key}.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "this" {
  for_each   = var.aws.resources.ec2
  key_name   = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-key-pair-${each.key}"
  public_key = tls_private_key.ec2_key[each.key].public_key_openssh
  tags       = merge(local.common_tags, each.value.key_pair_tags)
}

module "ec2" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "5.3.1"
  for_each                    = var.aws.resources.ec2
  name                        = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-ec2-${each.key}"
  instance_type               = each.value.instance_type
  ami                         = each.value.ami == null ? data.aws_ami.amazon-linux-2.id : each.value.ami
  key_name                    = aws_key_pair.this[each.key].key_name
  monitoring                  = each.value.monitoring
  vpc_security_group_ids      = [module.sg[each.value.sg].security_group_id]
  subnet_id                   = data.aws_subnets.ec2_network[each.key].ids[0]
  user_data_base64            = each.value.user_data != null ? base64encode(each.value.user_data) : null
  user_data_replace_on_change = each.value.user_data_replace_on_change
  enable_volume_tags          = false
  iam_instance_profile        = aws_iam_instance_profile.this[each.value.iam_instance_profile].name
  tags                        = merge(local.common_tags, each.value.tags)
  root_block_device = [
    {
      encrypted   = each.value.root_block_device.encrypted
      volume_type = each.value.root_block_device.volume_type
      throughput  = each.value.root_block_device.throughput
      volume_size = each.value.root_block_device.volume_size
      tags        = merge({ "Name" = "${var.aws.region}-${var.aws.profile}-ec2-${each.key}" }, local.common_tags, each.value.root_block_device.tags)
    }
  ]
}