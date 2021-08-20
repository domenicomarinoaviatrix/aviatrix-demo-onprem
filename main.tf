# Create private key for launching instances
resource "tls_private_key" "csr_deploy_key" {
  count     = var.key_name == null ? 1 : 0
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  count           = var.key_name == null ? 1 : 0
  content         = tls_private_key.csr_deploy_key[0].private_key_pem
  filename        = "${var.hostname}-key.pem"
  file_permission = "0600"
}

data "aviatrix_transit_gateway" "avtx_gateways" {
  for_each = toset(local.avtx_gateways)
  gw_name  = each.value
}

# Create public S2C+BGP Connections to transit
resource "aviatrix_transit_external_device_conn" "pubConns" {
  for_each          = { for conn in local.public_conns : "${conn.name}.${conn.tun_num}" => conn }
  vpc_id            = data.aviatrix_transit_gateway.avtx_gateways[each.value.name].vpc_id
  connection_name   = "${var.hostname}_to_${each.value.name}-${each.value.tun_num}"
  gw_name           = each.value.name
  connection_type   = "bgp"
  enable_ikev2      = true
  bgp_local_as_num  = each.value.as_num
  bgp_remote_as_num = var.csr_bgp_as_num
  ha_enabled        = false
  direct_connect    = false
  remote_gateway_ip = var.cloud_type == "aws" ? aws_eip.csr_public_eip[0].public_ip : azurerm_public_ip.csr_public_ip[0].ip_address
  pre_shared_key    = "aviatrix"
}

# Create private S2C+BGP Connections to transit
resource "aviatrix_transit_external_device_conn" "privConns" {
  for_each          = { for conn in local.private_conns : "${conn.name}.${conn.tun_num}" => conn }
  vpc_id            = data.aviatrix_transit_gateway.avtx_gateways[each.value.name].vpc_id
  connection_name   = "${var.hostname}_to_${each.value.name}-private-${each.value.tun_num}"
  gw_name           = each.value.name
  connection_type   = "bgp"
  enable_ikev2      = true
  bgp_local_as_num  = each.value.as_num
  bgp_remote_as_num = var.csr_bgp_as_num
  ha_enabled        = false
  direct_connect    = true
  remote_gateway_ip = var.cloud_type == "aws" ? tolist(aws_network_interface.CSR_Public_ENI[0].private_ips)[0] : azurerm_network_interface.csr_public_nic[0].private_ip_address
  pre_shared_key    = "aviatrix"
}
