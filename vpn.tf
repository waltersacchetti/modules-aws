resource "tls_private_key" "vpn_server" {
  for_each = var.aws.resources.vpn
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vpn_server" {
  for_each = var.aws.resources.vpn
  private_key_pem = tls_private_key.vpn_server[each.key].private_key_pem

  subject {
    common_name  = "vpn.${local.translation_regions[var.aws.region]}-${var.aws.profile}.${each.key}"
    organization = "Indra Transportes"
    country = "ES"
  }

  validity_period_hours = 43800
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "vpn_server" {
  for_each = var.aws.resources.vpn
  private_key = tls_private_key.vpn_server[each.key].private_key_pem
  certificate_body = tls_self_signed_cert.vpn_server[each.key].cert_pem
}

resource "tls_private_key" "vpn_client" {
  for_each = { for k, v in var.aws.resources.vpn : k => v if v.type == "certificate" }
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vpn_client" {
  for_each = { for k, v in var.aws.resources.vpn : k => v if v.type == "certificate" }
  private_key_pem = tls_private_key.vpn_client[each.key].private_key_pem

  subject {
    common_name  = "client.${local.translation_regions[var.aws.region]}-${var.aws.profile}.${each.key}"
    organization = "Indra Transportes"
    country = "ES"
  }

  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "vpn_client" {
  for_each = { for k, v in var.aws.resources.vpn : k => v if v.type == "certificate" }
  private_key = tls_private_key.vpn_client[each.key].private_key_pem
  certificate_body = tls_self_signed_cert.vpn_client[each.key].cert_pem
}

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

  server_certificate_arn = aws_acm_certificate.vpn_server[each.key].arn
  client_cidr_block      = each.value.client_cidr_block
  transport_protocol     = each.value.transport_protocol
  authentication_options {
    type              = "${each.value.type}-authentication"
    root_certificate_chain_arn = each.value.type == "certificate" ? aws_acm_certificate.vpn_client[each.key].arn : null
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