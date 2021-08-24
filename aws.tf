data "aws_region" "current" {}

#Create AWS VPC and Subnets
resource "aws_vpc" "csr_aws_vpc" {
  count      = var.cloud_type == "aws" ? 1 : 0
  cidr_block = var.network_cidr
}

resource "aws_subnet" "csr_aws_public_subnet" {
  count                   = var.cloud_type == "aws" ? 1 : 0
  vpc_id                  = aws_vpc.csr_aws_vpc.*.id[count.index]
  cidr_block              = var.public_sub
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    "Name" = "${var.hostname} Public Subnet"
  }
}

resource "aws_subnet" "csr_aws_private_subnet" {
  count                   = var.cloud_type == "aws" ? 1 : 0
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
  count  = var.cloud_type == "aws" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public Subnet IGW"
  }
}

#Create AWS Public and Private Subnet Route Tables
resource "aws_route_table" "csr_public_rtb" {
  count  = var.cloud_type == "aws" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public Route Table"
  }
}

resource "aws_route_table" "csr_private_rtb" {
  count  = var.cloud_type == "aws" ? 1 : 0
  vpc_id = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Private Route Table"
  }
}

resource "aws_route" "csr_public_default" {
  count                  = var.cloud_type == "aws" ? 1 : 0
  route_table_id         = aws_route_table.csr_public_rtb.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csr_igw.*.id[count.index]
  depends_on             = [aws_route_table.csr_public_rtb, aws_internet_gateway.csr_igw]
}

resource "aws_route" "csr_private_default" {
  count                  = var.cloud_type == "aws" ? 1 : 0
  route_table_id         = aws_route_table.csr_private_rtb.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.CSR_Private_ENI.*.id[count.index]
  depends_on             = [aws_route_table.csr_private_rtb, aws_instance.CSROnprem, aws_network_interface.CSR_Private_ENI]
}

resource "aws_route_table_association" "csr_public_rtb_assoc" {
  count          = var.cloud_type == "aws" ? 1 : 0
  subnet_id      = aws_subnet.csr_aws_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.csr_public_rtb.*.id[count.index]
}

resource "aws_route_table_association" "csr_private_rtb_assoc" {
  count          = var.cloud_type == "aws" ? 1 : 0
  subnet_id      = aws_subnet.csr_aws_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.csr_private_rtb.*.id[count.index]
}

resource "aws_security_group" "csr_public_sg" {
  count       = var.cloud_type == "aws" ? 1 : 0
  name        = "csr_public"
  description = "Security group for public CSR ENI"
  vpc_id      = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Public SG"
  }
}

resource "aws_security_group" "csr_private_sg" {
  count       = var.cloud_type == "aws" ? 1 : 0
  name        = "csr_private"
  description = "Security group for private CSR ENI"
  vpc_id      = aws_vpc.csr_aws_vpc.*.id[count.index]

  tags = {
    "Name" = "${var.hostname} Private SG"
  }
}

resource "aws_security_group_rule" "csr_public_ssh" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "client_forward_ssh" {
  count             = var.cloud_type == "aws" && var.create_client ? 1 : 0
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_dhcp" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 67
  to_port           = 67
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_ntp" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_snmp" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 161
  to_port           = 161
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_esp" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_ipsec" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_public_egress" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_private_ingress" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.*.id[count.index]
}

resource "aws_security_group_rule" "csr_private_egress" {
  count             = var.cloud_type == "aws" ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.*.id[count.index]
}

resource "aws_network_interface" "CSR_Public_ENI" {
  count             = var.cloud_type == "aws" ? 1 : 0
  subnet_id         = aws_subnet.csr_aws_public_subnet.*.id[0]
  security_groups   = [aws_security_group.csr_public_sg.*.id[0]]
  source_dest_check = false

  tags = {
    "Name" = "${var.hostname} Public Interface"
  }
}

resource "aws_network_interface" "CSR_Private_ENI" {
  count             = var.cloud_type == "aws" ? 1 : 0
  subnet_id         = aws_subnet.csr_aws_private_subnet.*.id[count.index]
  security_groups   = [aws_security_group.csr_private_sg.*.id[count.index]]
  source_dest_check = false

  tags = {
    "Name" = "${var.hostname} Private Interface"
  }
}

resource "aws_eip" "csr_public_eip" {
  count             = var.cloud_type == "aws" ? 1 : 0
  vpc               = true
  network_interface = aws_network_interface.CSR_Public_ENI.*.id[count.index]
  depends_on        = [aws_internet_gateway.csr_igw]

  tags = {
    "Name" = "${var.hostname} Public IP"
  }
}

resource "aws_key_pair" "csr_deploy_key" {
  count      = var.cloud_type == "aws" && var.key_name == null ? 1 : 0
  key_name   = "${var.hostname}_sshkey"
  public_key = tls_private_key.csr_deploy_key[0].public_key_openssh
}

data "aws_ami" "amazon-linux" {
  count       = var.cloud_type == "aws" && var.create_client ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_ami" "csr_aws_ami" {
  count  = var.cloud_type == "aws" ? 1 : 0
  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["cisco_CSR-.17.3.1a-BYOL-624f5bb1-7f8e-4f7c-ad2c-03ae1cd1c2d3-ami-0032671e883fdd77a.4"]
  }
}

resource "aws_instance" "test_client" {
  count                       = var.cloud_type == "aws" && var.create_client ? 1 : 0
  ami                         = data.aws_ami.amazon-linux.*.id[count.index]
  instance_type               = "t3.micro"
  key_name                    = var.key_name == null ? "${var.hostname}_sshkey" : var.key_name
  subnet_id                   = aws_subnet.csr_aws_private_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.csr_private_sg[0].id]
  associate_public_ip_address = false

  tags = {
    "Name" = "TestClient_${var.hostname}"
  }
}

data "aws_network_interface" "test_client_if" {
  count = var.cloud_type == "aws" && var.create_client ? 1 : 0
  id    = aws_instance.test_client[count.index].primary_network_interface_id
}

data "aws_instance" "CSROnprem" {
  count         = var.cloud_type == "aws" ? 1 : 0
  get_user_data = true
  filter {
    name   = "tag:Name"
    values = [var.hostname]
  }
  depends_on = [aws_instance.CSROnprem]
}

resource "aws_instance" "CSROnprem" {
  count         = var.cloud_type == "aws" ? 1 : 0
  ami           = data.aws_ami.csr_aws_ami.*.id[count.index]
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

  user_data = templatefile("${path.module}/csr_aws.sh", {
    public_conns   = aviatrix_transit_external_device_conn.pubConns
    private_conns  = aviatrix_transit_external_device_conn.privConns
    pub_conn_keys  = keys(aviatrix_transit_external_device_conn.pubConns)
    priv_conn_keys = keys(aviatrix_transit_external_device_conn.privConns)
    gateway        = data.aviatrix_transit_gateway.avtx_gateways
    hostname       = var.hostname
    test_client_ip = var.create_client ? data.aws_network_interface.test_client_if[0].private_ip : ""
    adv_prefixes   = var.advertised_prefixes
  })

  tags = {
    "Name" = var.hostname
  }
}
