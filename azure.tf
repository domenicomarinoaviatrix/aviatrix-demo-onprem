resource "azurerm_resource_group" "csrOnprem" {
  count    = var.cloud_type == "azure" && var.azure_rg == null ? 1 : 0
  name     = "${var.hostname}-rg"
  location = var.azure_location
}

resource "azurerm_network_security_group" "csr_private_nsg" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-private-nsg"
  location            = var.azure_location
  resource_group_name = local.azure_rg
}

resource "azurerm_network_security_group" "csr_public_nsg" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-public-nsg"
  location            = var.azure_location
  resource_group_name = local.azure_rg
}

resource "azurerm_network_security_rule" "csr_public_ssh" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "client_forward_ssh" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-client-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "2222"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_dhcp" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-dhcp"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "67"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_ntp" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-ntp"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "123"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_snmp" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-snmp"
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "161"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_esp" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-esp"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Esp"
  source_port_range           = "*"
  destination_port_range      = "500"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_ipsec" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-ipsec"
  priority                    = 106
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4500"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_public_egress" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-egress"
  priority                    = 107
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_public_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_private_ingress" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-private-ingress"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_private_nsg.*.name[count.index]
}

resource "azurerm_network_security_rule" "csr_private_egress" {
  count                       = var.cloud_type == "azure" ? 1 : 0
  name                        = "${var.hostname}-csr-private-egress"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.azure_rg
  network_security_group_name = azurerm_network_security_group.csr_private_nsg.*.name[count.index]
}

resource "azurerm_virtual_network" "csrOnprem-VNet" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-VNet"
  location            = var.azure_location
  resource_group_name = local.azure_rg
  address_space       = [var.network_cidr]

  tags = {
    environment = "${var.hostname}-staging"
  }
}

resource "azurerm_subnet" "csr_public_subnet" {
  count                = var.cloud_type == "azure" ? 1 : 0
  name                 = "${var.hostname}-public-subnet"
  resource_group_name  = local.azure_rg
  virtual_network_name = azurerm_virtual_network.csrOnprem-VNet.*.name[count.index]
  address_prefixes     = [var.public_sub]
}

resource "azurerm_subnet" "csr_private_subnet" {
  count                = var.cloud_type == "azure" ? 1 : 0
  name                 = "${var.hostname}-private-subnet"
  resource_group_name  = local.azure_rg
  virtual_network_name = azurerm_virtual_network.csrOnprem-VNet.*.name[count.index]
  address_prefixes     = [var.private_sub]
}

resource "azurerm_subnet_network_security_group_association" "csr_public_association" {
  count                     = var.cloud_type == "azure" ? 1 : 0
  subnet_id                 = azurerm_subnet.csr_public_subnet.*.id[count.index]
  network_security_group_id = azurerm_network_security_group.csr_public_nsg.*.id[count.index]
}

resource "azurerm_subnet_network_security_group_association" "csr_private_association" {
  count                     = var.cloud_type == "azure" ? 1 : 0
  subnet_id                 = azurerm_subnet.csr_private_subnet.*.id[count.index]
  network_security_group_id = azurerm_network_security_group.csr_private_nsg.*.id[count.index]
}

resource "azurerm_public_ip" "csr_public_ip" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-public-ip"
  resource_group_name = local.azure_rg
  location            = var.azure_location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "csr_private_nic" {
  count                = var.cloud_type == "azure" ? 1 : 0
  name                 = "${var.hostname}-private-nic"
  location             = var.azure_location
  resource_group_name  = local.azure_rg
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.hostname}-private"
    subnet_id                     = azurerm_subnet.csr_private_subnet.*.id[count.index]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "csr_public_nic" {
  count                = var.cloud_type == "azure" ? 1 : 0
  name                 = "${var.hostname}-public-nic"
  location             = var.azure_location
  resource_group_name  = local.azure_rg
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.hostname}-public"
    subnet_id                     = azurerm_subnet.csr_public_subnet.*.id[count.index]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.csr_public_ip.*.id[count.index]
  }
}

resource "azurerm_network_interface" "testclient_nic" {
  count               = var.cloud_type == "azure" && var.create_client ? 1 : 0
  name                = "${var.hostname}-testclient-nic"
  location            = var.azure_location
  resource_group_name = local.azure_rg

  ip_configuration {
    name                          = "${var.hostname}-private"
    subnet_id                     = azurerm_subnet.csr_private_subnet.*.id[count.index]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_route_table" "csr_public_rtb" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-public-rtb"
  location            = var.azure_location
  resource_group_name = local.azure_rg
}

resource "azurerm_route_table" "csr_private_rtb" {
  count               = var.cloud_type == "azure" ? 1 : 0
  name                = "${var.hostname}-private-rtb"
  location            = var.azure_location
  resource_group_name = local.azure_rg
}

resource "azurerm_subnet_route_table_association" "csr_public_rtb_assoc" {
  count          = var.cloud_type == "azure" ? 1 : 0
  subnet_id      = azurerm_subnet.csr_public_subnet.*.id[count.index]
  route_table_id = azurerm_route_table.csr_public_rtb.*.id[count.index]
}

resource "azurerm_subnet_route_table_association" "csr_private_rtb_assoc" {
  count          = var.cloud_type == "azure" ? 1 : 0
  subnet_id      = azurerm_subnet.csr_private_subnet.*.id[count.index]
  route_table_id = azurerm_route_table.csr_private_rtb.*.id[count.index]
}

resource "azurerm_route" "csr_private_default" {
  count                  = var.cloud_type == "azure" ? 1 : 0
  name                   = "${var.hostname}-private-default"
  resource_group_name    = local.azure_rg
  route_table_name       = azurerm_route_table.csr_private_rtb.*.name[count.index]
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.csr_private_nic.*.private_ip_address[count.index]
}

resource "azurerm_linux_virtual_machine" "CSROnprem" {
  count                 = var.cloud_type == "azure" ? 1 : 0
  name                  = var.hostname
  location              = var.azure_location
  resource_group_name   = local.azure_rg
  network_interface_ids = [azurerm_network_interface.csr_public_nic.*.id[count.index], azurerm_network_interface.csr_private_nic.*.id[count.index]]
  size                  = var.instance_type
  admin_username        = "adminuser"
  custom_data = base64encode(templatefile("${path.module}/csr_azure.sh", {
    public_conns   = aviatrix_transit_external_device_conn.pubConns
    private_conns  = aviatrix_transit_external_device_conn.privConns
    pub_conn_keys  = keys(aviatrix_transit_external_device_conn.pubConns)
    priv_conn_keys = keys(aviatrix_transit_external_device_conn.privConns)
    gateway        = data.aviatrix_transit_gateway.avtx_gateways
    hostname       = var.hostname
    test_client_ip = var.create_client ? azurerm_network_interface.testclient_nic.*.private_ip_address[count.index] : ""
    adv_prefixes   = var.advertised_prefixes
  }))

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.csr_deploy_key[0].public_key_openssh
  }

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "17_3_3-byol"
    version   = "latest"
  }

  plan {
    name      = "17_3_3-byol"
    product   = "cisco-csr-1000v"
    publisher = "cisco"
  }

  os_disk {
    name                 = "${var.hostname}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = "${var.hostname}-staging"
  }
}

resource "azurerm_linux_virtual_machine" "test_client" {
  count                 = var.cloud_type == "azure" && var.create_client ? 1 : 0
  name                  = "${var.hostname}-testclient"
  location              = var.azure_location
  resource_group_name   = local.azure_rg
  network_interface_ids = [azurerm_network_interface.testclient_nic.*.id[count.index]]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.csr_deploy_key[0].public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "${var.hostname}-testclient-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = "${var.hostname}-staging"
  }
}
