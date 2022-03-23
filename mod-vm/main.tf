data "azurerm_resource_group" "rg" {
  name = "rg-${var.project_name}"
}

data "azurerm_subnet" "snets" {
  for_each = var.snets_to_connect
  name                 = each.value.snet_name
  virtual_network_name = each.value.vnet_name
  resource_group_name  = each.value.vnet_rg_name
}

# Create public IP
resource "azurerm_public_ip" "pip" {
    name                         = "pip--${var.hostname}--${var.project_name}"
    location                     = data.azurerm_resource_group.rg.location
    resource_group_name          = data.azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"
}

data "azurerm_public_ip" "pip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_public_ip.pip.resource_group_name
  depends_on = [
    azurerm_linux_virtual_machine.vm,
  ] 
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "common-nsg" {
    name                = "commonNsg--${var.hostname}--${var.project_name}"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    security_rule {
        direction                  = "Inbound"
        priority                   = 1001
        name                       = "SSH"
        source_address_prefix      = "*"
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "22"
        protocol                   = "Tcp"
        access                     = "Allow"
    }

}

# Create network interface
resource "azurerm_network_interface" "nics" {
    for_each = data.azurerm_subnet.snets
    name                      = "nic--${each.key}--${var.hostname}"
    location                  = data.azurerm_resource_group.rg.location
    resource_group_name       = data.azurerm_resource_group.rg.name

    ip_configuration {
        name                          = each.value.name
        subnet_id                     = each.value.id
        private_ip_address_allocation = var.snets_to_connect[each.key].private_ip_address_allocation
        private_ip_address            = var.snets_to_connect[each.key].private_ip_address_allocation == "Static" ? var.snets_to_connect[each.key].private_ip_address : null
        # first nic will also include pip
        public_ip_address_id          = each.key == keys(data.azurerm_subnet.snets)[0] ? azurerm_public_ip.pip.id : null
    }

}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic-nsg-assoc" {
    for_each = azurerm_network_interface.nics
    network_interface_id      = each.value.id
    network_security_group_id = azurerm_network_security_group.common-nsg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
    name                  = "vm--${var.hostname}--${var.project_name}"
    location              = data.azurerm_resource_group.rg.location
    resource_group_name   = data.azurerm_resource_group.rg.name
    network_interface_ids = values(azurerm_network_interface.nics)[*].id
    size                  = var.size

    os_disk {
        name              = "disk--${var.hostname}--${var.project_name}"
        caching           = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
        version   = "20.04.202203080"
    }

    computer_name  = var.hostname
    admin_username = "uzer"
    disable_password_authentication = true
    custom_data = filebase64(var.cloudinitfile)
   #priority = "Spot"

    admin_ssh_key {
        username       = "uzer"
        public_key     = file("~/.ssh/id_rsa.pub")
    }
}


