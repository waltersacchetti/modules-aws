resource "aws_ec2_client_vpn_endpoint" "this" {
  for_each = var.aws.resources.vpn
  tags = merge(
                local.common_tags,
                each.value.tags,
                {
                  Name = "${local.translation_regions[var.aws.region]}-${var.aws.profile}-vpn-${each.key}"
                }
            )
  description            = "${each.key} - VPN for ${each.value.type} in VPC ${each.value.vpc}"

  server_certificate_arn = each.value.server_certificate_arn
  client_cidr_block      = each.value.client_cidr_block
  transport_protocol     = each.value.transport_protocol
  authentication_options {
    type              = "${each.value.type}-authentication"
    root_certificate_chain_arn = each.value.type == "certificate" ? each.value.root_certificate_chain_arn : null
    saml_provider_arn = each.value.type == "federated" ? "prueba" : null
  }
  connection_log_options {
    enabled = false
  }
  security_group_ids    = [module.sg[each.value.sg].security_group_id]
  split_tunnel          = each.value.split_tunnel
  session_timeout_hours = each.value.session_timeout_hours
  vpc_id                = module.vpc[each.value.vpc].vpc_id
  vpn_port              = each.value.vpn_port
}


resource "aws_ec2_client_vpn_network_association" "this" {
  for_each = var.aws.resources.vpn
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[each.key].id
  subnet_id              = element(data.aws_subnets.vpn_network[each.key].ids, 0)
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  for_each = var.aws.resources.vpn
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this[each.key].id
  target_network_cidr    = each.value.target_network_cidr
  authorize_all_groups   = true
}