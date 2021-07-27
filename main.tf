data "aws_region" "current" {}

locals {

  #Get unique list of Aviatrix Gateways to pull data sources for
  avtx_gateways = distinct(flatten([[for gateway in var.public_conns : split(":", gateway)[0]], [for gateway in var.private_conns : split(":", gateway)[0]]]))

  #Create flattened list of maps in format: [{name=>gw_name, as_num=>bgp_as_num, tun_num=>x}, ...]
  #This list will be iterated through to create the Aviatrix external conn resources
  public_conns = flatten([for gateway in var.public_conns :
    [for i in range(tonumber(split(":", gateway)[2])) : {
      "name"    = split(":", gateway)[0]
      "as_num"  = split(":", gateway)[1]
      "tun_num" = i + 1
      }
    ]
  ])

  private_conns = flatten([for gateway in var.private_conns :
    [for i in range(tonumber(split(":", gateway)[2])) : {
      "name"    = split(":", gateway)[0]
      "as_num"  = split(":", gateway)[1]
      "tun_num" = i + 1
      }
    ]
  ])

}

#Create AWS VPC and Subnets
resource "aws_vpc" "csr_aws_vpc" {
  count      = var.aws_deploy_csr == "true" ? 1 : 0
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "csr_aws_public_subnet" {
  count                   = var.aws_deploy_csr == "true" ? 1 : 0
  vpc_id                  = aws_vpc.csr_aws_vpc.*.id[count.index]
  cidr_block              = var.public_sub
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    "Name" = "${var.hostname} Public Subnet"
  }
}

resource "aws_subnet" "csr_aws_private_subnet" {
  count                   = var.aws_deploy_csr == "true" ? 1 : 0
  vpc_id                  = aws_vpc.csr_aws_vpc.*.id[count.index]
  cidr_block              = var.private_sub
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    "Name" = "${var.hostname} Private Subnet"
  }
}

#Create IGW for public subnet
resource "aws_internet_gateway" "csr_igw" {
  count  = var.aws_deploy_csr == "true" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public Subnet IGW"
  }
}

#Create AWS Public and Private Subnet Route Tables
resource "aws_route_table" "csr_public_rtb" {
  count  = var.aws_deploy_csr == "true" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public Route Table"
  }
}

resource "aws_route_table" "csr_private_rtb" {
  count  = var.aws_deploy_csr == "true" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Private Route Table"
  }
}

resource "aws_route" "csr_public_default" {
  count                  = var.aws_deploy_csr == "true" ? 1 : 0
  route_table_id         = aws_route_table.csr_public_rtb.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csr_igw.*.id[count.index]
  depends_on             = [aws_route_table.csr_public_rtb, aws_internet_gateway.csr_igw]
}

resource "aws_route" "csr_private_default" {
  count                  = var.aws_deploy_csr == "true" ? 1 : 0
  route_table_id         = aws_route_table.csr_private_rtb.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.CSR_Private_ENI.*.id[count.index]
  depends_on             = [aws_route_table.csr_private_rtb, aws_instance.CSROnprem, aws_network_interface.CSR_Private_ENI]
}

resource "aws_route_table_association" "csr_public_rtb_assoc" {
  count          = var.aws_deploy_csr == "true" ? 1 : 0
  subnet_id      = aws_subnet.csr_aws_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.csr_public_rtb.*.id[count.index]
}

resource "aws_route_table_association" "csr_private_rtb_assoc" {
  count          = var.aws_deploy_csr == "true" ? 1 : 0
  subnet_id      = aws_subnet.csr_aws_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.csr_private_rtb.*.id[count.index]
}

resource "aws_security_group" "csr_public_sg" {
  count       = var.aws_deploy_csr == "true" ? 1 : 0
  name        = "csr_public"
  description = "Security group for public CSR ENI"
  vpc_id      = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public SG"
  }
}

resource "aws_security_group" "csr_private_sg" {
  count       = var.aws_deploy_csr == "true" ? 1 : 0
  name        = "csr_private"
  description = "Security group for private CSR ENI"
  vpc_id      = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Private SG"
  }
}

resource "aws_security_group_rule" "csr_public_ssh" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "client_forward_ssh" {
  count             = var.create_client ? 1 : 0
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_dhcp" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 67
  to_port           = 67
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_ntp" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_snmp" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 161
  to_port           = 161
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_esp" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_ipsec" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_egress" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_private_ingress" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_private_egress" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.*.id[count.index]
}

resource "aws_network_interface" "CSR_Public_ENI" {
  subnet_id         = aws_subnet.csr_aws_public_subnet.*.id[0]
  security_groups   = [aws_security_group.csr_public_sg.*.id[0]]
  source_dest_check = false

  tags = {
    "Name" = "${var.hostname} Public Interface"
  }
}

resource "aws_network_interface" "CSR_Private_ENI" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  subnet_id         = aws_subnet.csr_aws_private_subnet.*.id[count.index]
  security_groups   = [aws_security_group.csr_private_sg.*.id[count.index]]
  source_dest_check = false

  tags = {
    "Name" = "${var.hostname} Private Interface"
  }
}

resource "aws_eip" "csr_public_eip" {
  count             = var.aws_deploy_csr == "true" ? 1 : 0
  vpc               = true
  network_interface = aws_network_interface.CSR_Public_ENI.*.id[count.index]
  depends_on        = [aws_internet_gateway.csr_igw]

  tags = {
    "Name" = "${var.hostname} Public IP"
  }
}

resource "tls_private_key" "csr_deploy_key" {
  count     = var.key_name == null ? 1 : 0
  algorithm = "RSA"
}

resource "aws_key_pair" "csr_deploy_key" {
  count      = var.key_name == null ? 1 : 0
  key_name   = "${var.hostname}_sshkey"
  public_key = tls_private_key.csr_deploy_key[0].public_key_openssh
}

resource "local_file" "private_key" {
  count           = var.key_name == null ? 1 : 0
  content         = tls_private_key.csr_deploy_key[0].private_key_pem
  filename        = "private_key.pem"
  file_permission = "0600"
}

data "aviatrix_transit_gateway" "avtx_gateways" {
  for_each = toset(local.avtx_gateways)
  gw_name  = each.value
}

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
  remote_gateway_ip = aws_eip.csr_public_eip[0].public_ip
  pre_shared_key    = "aviatrix"
}

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
  remote_gateway_ip = tolist(aws_network_interface.CSR_Public_ENI.private_ips)[0]
  pre_shared_key    = "aviatrix"
}

data "aws_ami" "amazon-linux" {
  count       = var.create_client ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_ami" "csr_aws_ami" {
  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["cisco_CSR-.17.3.1a-BYOL-624f5bb1-7f8e-4f7c-ad2c-03ae1cd1c2d3-ami-0032671e883fdd77a.4"]
  }
}

resource "aws_instance" "test_client" {
  count                       = var.create_client ? 1 : 0
  ami                         = data.aws_ami.amazon-linux.*.id[count.index]
  instance_type               = "t2.micro"
  key_name                    = var.key_name == null ? "${var.hostname}_sshkey" : var.key_name
  subnet_id                   = aws_subnet.csr_aws_private_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.csr_private_sg[0].id]
  associate_public_ip_address = false

  tags = {
    "Name" = "TestClient_${var.hostname}"
  }
}

data "aws_network_interface" "test_client_if" {
  count = var.create_client ? 1 : 0
  id    = aws_instance.test_client[count.index].primary_network_interface_id
}

data "aws_instance" "CSROnprem" {
  get_user_data = true
  filter {
    name   = "tag:Name"
    values = [var.hostname]
  }
  depends_on = [aws_instance.CSROnprem]
}

resource "aws_instance" "CSROnprem" {
  count         = var.aws_deploy_csr == "true" ? 1 : 0
  ami           = data.aws_ami.csr_aws_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name == null ? "${var.hostname}_sshkey" : var.key_name

  network_interface {
    network_interface_id = aws_network_interface.CSR_Public_ENI.*.id[count.index]
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.CSR_Private_ENI.*.id[count.index]
    device_index         = 1
  }

  user_data = templatefile("${path.module}/csr.sh", {
    public_conns   = aviatrix_transit_external_device_conn.pubConns
    private_conns  = aviatrix_transit_external_device_conn.privConns
    pub_conn_keys  = keys(aviatrix_transit_external_device_conn.pubConns)
    priv_conn_keys = keys(aviatrix_transit_external_device_conn.privConns)
    gateway        = data.aviatrix_transit_gateway.avtx_gateways
    hostname       = var.hostname
    test_client_ip = var.create_client ? data.aws_network_interface.test_client_if[0].private_ip : ""
  })

  tags = {
    "Name" = var.hostname
  }
}
