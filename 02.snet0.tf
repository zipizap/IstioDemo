# Create subnet
resource "azurerm_subnet" "snet0" {
    name                 = "snet0-${var.project_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet0.name
    address_prefixes       = ["10.0.0.0/24"]
}
 

